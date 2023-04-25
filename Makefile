.DEFAULT_GOAL:=help

ROOT_DIR_MAKEFILE_POS:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH_SCRIPTS=${ROOT_DIR_MAKEFILE_POS}/scripts
PATH_SCRIPTS_DATASYNC=${PATH_SCRIPTS}/data_sync
PATH_TMP=${ROOT_DIR_MAKEFILE_POS}/tmp
PATH_CREDENTIALS=${PATH_TMP}/credentials
GS_ETL_DATASET:=$(shell test -f config.tfvars && cat config.tfvars | grep config_gs_etl | awk -F= '{print $$2}' | tr -d ' "')
GS_SYNC_FROM:=$(shell test -f config.tfvars && cat config.tfvars | grep gs_sync_from | awk -F= '{print $$2}' | tr -d ' "')
PROJECT_ID_DEV=$(shell test -f config.tfvars && cat config.tfvars | grep config_project_id | awk -F= '{print $$2}' | tr -d ' "')
RELEASE_ID_DEV=$(shell test -f config.tfvars && cat config.tfvars | grep release_id_dev | awk -F= '{print $$2}' | tr -d ' "')
RELEASE_ID_PROD=$(shell test -f config.tfvars && cat config.tfvars | grep release_id_prod | awk -F= '{print $$2}' | tr -d ' "')
TF_WORKSPACE_ID=$(shell uuidgen | tr '''[:upper:]''' '''[:lower:]''' | cut -f5 -d'-')
PATH_GCS_CREDENTIALS_FILE=${PATH_CREDENTIALS}/gcs_credentials.json
PATH_GCS_CREDENTIALS_GCP_FILE="gs://open-targets-ops/credentials/pis-service_account.json"
TF_WORKSPACE_ID_FILE='terraform_workspace_id'

export ROOT_DIR_MAKEFILE_POS
export GS_ETL_DATASET
export GS_SYNC_FROM
export PROJECT_ID_DEV
export RELEASE_ID_DEV
export RELEASE_ID_PROD
export PATH_GCS_CREDENTIALS_FILE

check:
	[ -e "/you/file.file" ] && echo 1 || $error("Bad svnversion v1.4, please install v1.6")

help: ## show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

tmp: # Create a temporary directory
	@mkdir -p ${PATH_TMP}

credentials: ## Create a credentials file for Google Cloud
	@echo "[GOOGLE] Creating credentials file"
	@mkdir -p ${PATH_CREDENTIALS}
	@gsutil cp ${PATH_GCS_CREDENTIALS_GCP_FILE} ${PATH_GCS_CREDENTIALS_FILE}

set_profile: ## Set an active configuration profile, e.g. "make set_profile profile='development'" (see folder 'profiles')
	@echo "[POS] Setting active profile '${profile}'"
	@ln -sf profiles/config.${profile} config.tfvars
	@cd terraform_create_images; ln -sf ../profiles/config.${profile} terraform.tfvars

clean_profile: ## Clean the active configuration profile
	@echo "[POS] Cleaning active profile"
	@rm -f config.tfvars
	@rm -f terraform_create_images/terraform.tfvars

image: ## Create Google cloud Clickhouse image and ElasticSearch image.
	@cd ${ROOT_DIR_MAKEFILE_POS}/terraform_create_images ; \
		export tf_id="${TF_WORKSPACE_ID}" && \
		echo "[TERRAFORM] Using Terraform Workspace ID '$${tf_id}'" && \
		terraform init && \
		terraform workspace new $${tf_id} && \
		echo "$${tf_id}" > ${TF_WORKSPACE_ID_FILE} && \
		terraform apply -auto-approve

clean_image_infrastructure: ## Clean the infrastructure used for creating the data images
	@cd ${ROOT_DIR_MAKEFILE_POS}/terraform_create_images ; \
		export tf_id=$$(cat ${TF_WORKSPACE_ID_FILE}) && \
		terraform destroy -auto-approve && \
		echo "[TERRAFORM] Cleaning up Workspace ID '$${tf_id}'" ; \
		terraform workspace select default && \
		terraform workspace delete $${tf_id} && \
		rm ${TF_WORKSPACE_ID_FILE}

clean_all_image_infrastructure: ## Clean all the infrastructures used for creating data images
	@cd ${ROOT_DIR_MAKEFILE_POS}/terraform_create_images ; \
	terraform init && \
	terraform workspace select default && \
	for ws in $$( terraform workspace list | cut -f2 -d'*' ) ; do \
		if [ $$ws != 'default' ] ; then \
			echo "[CLEAN] Terraform workspace '$$ws'"; \
			terraform workspace select $$ws ; \
			terraform destroy -auto-approve ; \
			terraform workspace select default ; \
			terraform workspace delete $$ws ; \
		fi \
	done

clean_tmp: ## Clean the temporary directory
	@rm -rf tmp

clean: clean_tmp clean_image_infrastructure ## Clean the temporary directory and the infrastructure used for creating data images

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
    export RELEASE_ID=${RELEASE_ID_PROD}; \
	${ROOT_DIR_MAKEFILE_POS}/deploy_bq/create_bq.sh

sync: tmp credentials ## Sync data to EBI FTP service
	@echo "==== Sync ===="
	export GS_SYNC_FROM=${GS_SYNC_FROM}; \
	${PATH_SCRIPTS_DATASYNC}/launch_ebi_ftp_sync.sh

syncgs: ## Copy data from pre-release to production
	@echo "==== Sync ===="
	@echo "Sync from '${GS_SYNC_FROM}'"
	@echo "Release ID '${RELEASE_ID_PROD}'"
	${PATH_SCRIPTS_DATASYNC}/syncgs.sh

.PHONY: credentials clean clean_profile syncgs sync bigqueryprod bigquerydev set_profile image clean_image_infrastructure clean_all_image_infrastructure