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

## Credits

Thanks and gratitude to these creators and references that I have sourced code from:
- https://github.com/8grams/ansible-microk8s/blob/main/install_microk8s.yaml
- https://github.com/sredevopsorg/ghost-on-kubernetes