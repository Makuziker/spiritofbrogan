# Spirit of Brogan

Source code for the website https://spiritofbrogan.com/

Built with Terraform/Terragrunt, Ansible, MicroK8s, and Ghost. Ghost infrastructure consists of a single-node K8s cluster, two pods each with persistent volumes.

## Setup

This show how to prepare your local machine for development. Command instructions are included for Mac installation.

- Install Terraform v1.7.4
- Install Terragrunt >=0.55.13

```
cd spiritofbrogan/
brew install tfenv
# Install Terraform version from .terraform-version
tfenv install
# Optional
tfenv use v1.7.4
brew install terragrunt
terraform --version
terragrunt --version
```

- Install Ansible

```
brew install pipx
pipx ensurepath
pipx install --include-deps ansible
ansible --version
```

- Install MicroK8s

```
brew install ubuntu/microk8s/microk8s
microk8s install
microk8s status --wait-ready
# You may want to `microk8s disable ha-cluster` with a single-node installation
microk8s enable dns cert-manager dashboard dns registry istio ingress hostpath-storage
```

- Go to GCP console. Create a new project. Create a GCP service user with "Edit" permission in that account. This will be necessary for executing Terraform. Enable Compute Engine API for project.

- Download and reference GCP service user credentials file.

```
cd spiritofbrogan/
mv <your_gcp_key_name> keys/gcp_credentials.json
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/keys/gcp_credentials.json"
```

- Initialize Terragrunt

```
cd tf/live/gcp
terragrunt run-all init
```

- Generate SSH key pair for VM access.

```
cd spiritofbrogan/
openssl genpkey -algorithm RSA -out keys/devops_user.pem
openssl rsa -pubout -in keys/devops_user.pem -out keys/devops_user.pub
ls -l keys
```

- Generate CSR and private key files for domain name.

- Configure other private files
  - tf/live/admin_vars.yaml
  - k8s/01-secrets.yaml
  - k8s/04-config.production.yaml

## Launch

Provision the infrastructure with Terragrunt. Configure and deploy the K8s Ghost application with Ansible.

```
cd tf/live/gcp
terragrunt run-all plan
terragrunt run-all apply

# Get VM ephemeral public IP from GCP, store in ansible/inventory.yaml

cd ../../.. # back to project root dir.
ansible-playbook ansible/health_check.yaml
ansible-playbook ansible/install_microk8s.yaml
ansible-playbook ansible/deploy_ghost.yaml

# SSH to remote VM
ssh -i keys/devops_user.pem devops_user@<vm_public_ip>
```
Access website Ghost console at https://example.com/ghost. Create your admin user. Download and enable a theme for the main site to become available.

# Setup Kubeconfig (basic)

We can use the default microk8s config like so:
- SSH to Ubuntu machine
- Run `microk8s config -l` to generate the default kubeconfig for loopback access.
- Merge this config output with your local `~/.kube/config` file, or `spiritofbrogan/.kube/config`.
- Set the current-context if necessary.
- Setup SSH port forwarding so that your 127.0.0.1:16443 maps to the remote 127.0.0.1:16443.

```
# Set the custom path to kubeconfig
# export KUBECONFIG=$(pwd)/.kube/config
# Check that the microk8s-cluster context is selected
# microk8s kubectl config get-contexts
# SSH localhost port forwarding tunnel.
ssh -L localhost:16443:localhost:16443 devops_user@35.212.182.22 -i keys/devops_user.pem
# Check connectivity
microk8s kubectl get pod -n ghost-k8s
# or
kubectl get pod -n ghost-k8s
```

# Resize an existing microk8s-hostpath Persistent Volume

Say that the ghost static storage is getting full. The commands below demonstrate how to resize the existing static storage PV without data loss. Adjust the `pv` accordingly, and the new storage in `GiB`.

```
microk8s kubectl get pv -n ghost-k8s # Get PV ID

microk8s kubectl patch pv pvc-7aa7e7b5-be0c-4231-a900-68913ccf7f34 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

microk8s kubectl get pv -n ghost-k8s # Check RECLAIM POLICY is Retain

microk8s kubectl delete -f k8s/06-ghost-deployment.yaml -n ghost-k8s

microk8s kubectl delete pvc ghost-k8s-static-ghost -n ghost-k8s

microk8s kubectl get pv -n ghost-k8s # check STATUS is Released

microk8s kubectl patch pv pvc-7aa7e7b5-be0c-4231-a900-68913ccf7f34 -p '{"spec":{"capacity":{"storage":"11Gi"}}}' -n ghost-k8s

microk8s kubectl get pv -n ghost-k8s # check CAPACITY is 11GiB

microk8s kubectl patch pv pvc-7aa7e7b5-be0c-4231-a900-68913ccf7f34 -p '{"spec":{"claimRef": null}}' -n ghost-k8s 

microk8s kubectl get pv -n ghost-k8s # check STATUS is available

# Edit 02-pvc.yaml static-storage PVC. `storage` to match with the PV. `volumeName` to match the pv ID.

microk8s kubectl apply -f k8s/02-pvc.yaml  -n ghost-k8s

microk8s kubectl get pvc -n ghost-k8s

microk8s kubectl apply -f k8s/06-ghost-deployment.yaml -n ghost-k8s

microk8s kubectl get pod -n ghost-k8s

# Verify that the pvc is mounted, with the right size, and the site comes back online.
```

## Import existing K8s resources into a Helm chart

Create a basic Helm chart, with a subchart for ghost-k8s.

We can see that Helm does not manage these resources when it is lacking the Labels and Annotations:

```sh
kubectl describe secret mysql-ghost-k8s -n ghost-k8s
Name:         mysql-ghost-k8s
Namespace:    ghost-k8s
Labels:       <none>
Annotations:  <none>
# ...
```

Run the below commands to add Helm metadata to existing resources.

```sh
# Kudos to https://jacky-jiang.medium.com/import-existing-resources-in-helm-3-e27db11fd467 for the bulk labelling script.
NAMESPACE=ghost-k8s
RELEASE_NAME="<your_release_name>" # Was chart-1711855390
KINDS=secret,pv,pvc,svc,statefulset,deploy,ing

kubectl label namespace/$NAMESPACE app.kubernetes.io/managed-by=Helm
kubectl annotate --overwrite namespace/$NAMESPACE meta.helm.sh/release-name=$RELEASE_NAME
kubectl annotate namespace/$NAMESPACE meta.helm.sh/release-namespace=$NAMESPACE

kubectl get -n $NAMESPACE $KINDS -o name | xargs -I % kubectl label -n $NAMESPACE % app.kubernetes.io/managed-by=Helm
kubectl get -n $NAMESPACE $KINDS -o name | xargs -I % kubectl annotate --overwrite -n $NAMESPACE % meta.helm.sh/release-name=$RELEASE_NAME
kubectl get -n $NAMESPACE $KINDS -o name | xargs -I % kubectl annotate -n $NAMESPACE % meta.helm.sh/release-namespace=$NAMESPACE

# Now our K8s resources have the Helm Labels and Annotations:
kubectl get deploy -o name -n $NAMESPACE | xargs -I % kubectl describe % -n $NAMESPACE
# Name:               ghost-k8s
# Namespace:          ghost-k8s
# CreationTimestamp:  Mon, 18 Mar 2024 18:39:44 -0600
# Labels:             app.kubernetes.io/managed-by=Helm
# Annotations:        deployment.kubernetes.io/revision: 2
#                     meta.helm.sh/release-name: chart-1711855390
#                     meta.helm.sh/release-namespace: ghost-k8s
# ...

# If you do not provide --namespace, Helm may target whatever is assigned to `$HELM_NAMESPACE`, which is most likely "default".

# Install the Helm chart
helm install --dry-run=server $RELEASE_NAME --namespace $NAMESPACE .
helm install $RELEASE_NAME --namespace $NAMESPACE .
```

## Todos

- Show dashboard locally for remote cluster.
- Add Vault service to K8s cluster with ConfigMap.
  - Vault contains the secrets (DB credentials), ConfigMap can manually or automatically source from Vault. Check out plugins for connecting them.
- Look into Golang custom K8s libraries. How they define K8s modules (via `api: `) that we can call and instantiate.
- Sidecar pattern on application pod for logging and metrics collection.

## Credits

Thanks and gratitude to these creators and references that I have sourced code from:
- https://github.com/8grams/ansible-microk8s/blob/main/install_microk8s.yaml
- https://github.com/sredevopsorg/ghost-on-kubernetes