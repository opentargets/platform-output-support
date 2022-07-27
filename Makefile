.DEFAULT_GOAL:=help

ROOT_DIR_MAKEFILE_POS:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
GS_ETL_DATASET:=$(shell cat config.tfvars | grep config_gs_etl | awk -F= '{print $$2}' | tr -d ' "')
GS_SYNC_FROM:=$(shell cat config.tfvars | grep gs_sync_from | awk -F= '{print $$2}' | tr -d ' "')
PROJECT_ID_DEV=$(shell cat config.tfvars | grep config_project_id | awk -F= '{print $$2}' | tr -d ' "')
RELEASE_ID_DEV=$(shell cat config.tfvars | grep release_id_dev | awk -F= '{print $$2}' | tr -d ' "')
RELEASE_ID_PROD=$(shell cat config.tfvars | grep release_id_prod | awk -F= '{print $$2}' | tr -d ' "')
TF_WORKSPACE_ID=$(shell uuidgen | tr '''[:upper:]''' '''[:lower:]''' | cut -f5 -d'-')
TF_WORKSPACE_ID_FILE='terraform_workspace_id'

export ROOT_DIR_MAKEFILE_POS
export GS_ETL_DATASET
export GS_SYNC_FROM
export PROJECT_ID_DEV
export RELEASE_ID_DEV
export RELEASE_ID_PROD

check:
	[ -e "/you/file.file" ] && echo 1 || $error("Bad svnversion v1.4, please install v1.6")

help: ## show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

image: ## Create Google cloud Clickhouse image and ElasticSearch image.
	@echo ${ROOT_DIR_MAKEFILE_POS}
	@cp ${ROOT_DIR_MAKEFILE_POS}/config.tfvars ${ROOT_DIR_MAKEFILE_POS}/terraform_create_images/terraform.tfvars
	@cd ${ROOT_DIR_MAKEFILE_POS}/terraform_create_images ; \
		export tf_id="${TF_WORKSPACE_ID}" && \
		echo "[TERRAFORM] Using Terraform Workspace ID '$${tf_id}'" && \
		terraform init && \
		terraform workspace new $${tf_id} && \
		echo "$${tf_id}" > ${TF_WORKSPACE_ID_FILE} && \
		terraform apply -auto-approve

bigquerydev:  ## Big Query Dev
	@echo $(PROJECT_ID_DEV)
	@echo "==== Big Query DEV ===="
	export PROJECT_ID=${PROJECT_ID_DEV}; \
	export RELEASE_ID=${RELEASE_ID_DEV}; \
	 ${ROOT_DIR_MAKEFILE_POS}/deploy_bq/create_bq.sh


bigqueryprod:## Big Query Production
	@echo "==== Big Query DEV ===="
	@echo ${GS_ETL_DATASET}
	export PROJECT_ID=open-targets-prod; \
    export RELEASE_ID=${RELEASE_ID_PROD}; \${ROOT_DIR_MAKEFILE_POS}/deploy_bq/create_bq.sh

sync:## Sync data to production
	@echo "==== Sync ===="
	@echo ${GS_SYNC_FROM}
	@echo ${RELEASE_ID_PROD}
	bsub < ${ROOT_DIR_MAKEFILE_POS}/sync_data_to_prod/sync_to_ebi_ftp.sh

syncgs: ## Copy data from pre-release to production
	@echo "==== Sync ===="
	@echo ${GS_SYNC_FROM}
	@echo ${RELEASE_ID_PROD}
	${ROOT_DIR_MAKEFILE_POS}/sync_data_to_prod/syncgs.sh
