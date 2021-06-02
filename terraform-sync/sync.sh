export TF_VAR_ftp_credential=$(< credentials/ftp-key.txt )
export TF_VAR_prod_credential=$(< credentials/open-targets-prod.json )
export TF_VAR_eu_dev_credential=$(< credentials/open-targets-eu-dev.json )
terraform init
#terraform plan -var-file="deployment_context.tfvars"
terraform apply -var-file="deployment_context.tfvars"