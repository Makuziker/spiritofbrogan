# spiritofbrogan


## Setup

Install Terraform v1.7.4
Install Terragrunt >=0.55.13
Install Ansible vx.x.x
Install MicroK8s

Download and reference GCP service user credentials file.
```
cd <project_root_dir>
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/keys/<gcp_key_name>.json"
```