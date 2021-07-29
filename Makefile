.DEFAULT_GOAL:=help

#cat config.tfvars | grep release_id_prod | awk -F= '{print $2}' | tr -d ' "'
ROOT_DIR_MAKEFILE_POS:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

GS_ETL_DATASET:=$(shell cat config.tfvars | grep config_gs_etl | awk -F= '{print $$2}' | tr -d ' "')
RELEASE_ID:=$(shell cat config.tfvars | grep release_id | awk -F= '{print $$2}' | tr -d ' "')

export ROOT_DIR_MAKEFILE_POS
export GS_ETL_DATASET
export RELEASE_ID
check:
	[ -e "/you/file.file" ] && echo 1 || $error("Bad svnversion v1.4, please install v1.6")

help: ## show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

image: ## Create Google cloud Clickhouse image and ElasticSearch image.
	@echo ${ROOT_DIR_MAKEFILE_POS}
	cp ${ROOT_DIR_MAKEFILE_POS}/config.tfvars ${ROOT_DIR_MAKEFILE_POS}/terraform_create_images/deployment_context.tfvars
	${ROOT_DIR_MAKEFILE_POS}/terraform_create_images/run.sh

bigquerydev: export PROJECT_ID:=$(shell cat config.tfvars | grep config_project_id | awk -F= '{print $$2}' | tr -d ' "')

bigquerydev: ## Big Query Dev
	@echo "==== Big Query DEV ===="
	@echo ${GS_ETL_DATASET}
	@echo ${PROJECT_ID}
	${ROOT_DIR_MAKEFILE_POS}/deploy_bq/create_bq.sh

bigqueryprod: export PROJECT_ID:=open-targets-prod

bigqueryprod: ## Big Query Production
	@echo "==== Big Query DEV ===="
	@echo ${GS_ETL_DATASET}
	@echo ${PROJECT_ID}
	${ROOT_DIR_MAKEFILE_POS}/deploy_bq/create_bq.sh

sync: ## percent included
appengine: ## parenthesis
graphql: ## both
