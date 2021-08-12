#!/bin/bash

echo "=== Please read README file for setting up  your account ==="
echo $ROOT_DIR_MAKEFILE_POS
cd $ROOT_DIR_MAKEFILE_POS/terraform_create_images
terraform init
terraform apply -auto-approve -var-file="deployment_context.tfvars"


#terraform destroy -auto-approve -var-file="deployment_context.tfvars"
#rm deployment_context.tfvars