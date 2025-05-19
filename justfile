profile := 'default'
profile_tfvars := if path_exists(join("profiles", profile + ".tfvars")) == "true" {
  join("profiles", profile + ".tfvars")
 } else {
  error('Profile does not exist')
 }


PATH_CREDENTIALS := justfile_directory() / ".credentials"
PATH_GCS_CREDENTIALS_FILE := PATH_CREDENTIALS / "gcs_credentials.json"
PATH_GCS_CREDENTIALS_GCP_FILE := "gs://open-targets-ops/credentials/pis-service_account.json"
PATH_POS_YAML_CONFIG := justfile_directory() / "config" / "config.yaml"
PATH_DATA_RELEASE_CONFIG := justfile_directory() / ".data_release_config.yaml"
TF_DIRECTORY := "deployment"
TF_WORKSPACE_ID := replace_regex(lowercase(uuid()), "[[:alnum:]]+-", "")
TF_WORKSPACE_ID_FILE := TF_DIRECTORY / ".workspace_id"

help:
  @just --list --unsorted --list-heading $'Platform Output Support\nSet the profile with `just profile=foo <RECIPE>` to use `profiles/foo.tfvars`. Defaults to `profiles/default.tfvars` if no profile is set.\n'

# Create a credentials file for Google Cloud
_credentials:
	@echo "Creating credentials file"
	@mkdir -p {{PATH_CREDENTIALS}}
	@gcloud storage cp {{PATH_GCS_CREDENTIALS_GCP_FILE}} {{PATH_GCS_CREDENTIALS_FILE}} 

# Set the profile to substitute any terraform variables. e.g. `just profile=foo set_profile` to use `profiles/foo.tfvars`. Defaults to `profiles/default.tfvars` if no profile is set.
_set_profile:
  @echo 'Setting active profile to {{profile_tfvars}}'
  @ln -sf ../{{profile_tfvars}} {{TF_DIRECTORY}}/terraform.tfvars;

# Create Google cloud disk snapshots (Clickhouse and OpenSearch). 
snapshots: _set_profile
	@echo {{TF_WORKSPACE_ID}}
	@export tf_id={{TF_WORKSPACE_ID}} && \
	echo "Using Terraform Workspace ID ${tf_id}" && \
	echo ${tf_id} > {{TF_WORKSPACE_ID_FILE}} && \
	terraform -chdir={{TF_DIRECTORY}} init && \
	terraform -chdir={{TF_DIRECTORY}} workspace new ${tf_id} && \
	terraform -chdir={{TF_DIRECTORY}} apply 

# Clean the infrastructure used for creating the Google cloud disk snapshots
_clean_snapshot_infrastructure:
	@export tf_id=$(cat {{TF_WORKSPACE_ID_FILE}}) && \
	terraform -chdir={{TF_DIRECTORY}} destroy -auto-approve && \
	echo "Cleaning up Workspace ID ${tf_id}" && \
	terraform -chdir={{TF_DIRECTORY}} workspace select default && \
	terraform -chdir={{TF_DIRECTORY}} workspace delete ${tf_id} && \
	rm {{TF_WORKSPACE_ID_FILE}}

# Clean all the infrastructures used for creating the Google cloud disk snapshots
_clean_all_snapshot_infrastructure: 
	@terraform -chdir={{TF_DIRECTORY}} init && \
	terraform -chdir={{TF_DIRECTORY}} workspace select default && \
	for ws in $( terraform -chdir={{TF_DIRECTORY}} workspace list | cut -f2 -d'*' ) ; do \
		if [ $ws != 'default' ] ; then \
			echo "Terraform workspace $ws"; \
			terraform -chdir={{TF_DIRECTORY}} workspace select $ws ; \
			terraform -chdir={{TF_DIRECTORY}} destroy -auto-approve ; \
			terraform -chdir={{TF_DIRECTORY}} workspace select default ; \
			terraform -chdir={{TF_DIRECTORY}} workspace delete $ws ; \
		fi \
	done

# Clean up the credentials
_clean_credentials:
	@echo "Cleaning up credentials"
	@rm -rf {{PATH_CREDENTIALS}}

# Clean the credentials and the infrastructure used for creating the Google cloud disk snapshots
clean: _clean_credentials _clean_snapshot_infrastructure

clean_all: _clean_credentials _clean_all_snapshot_infrastructure

_uv_sync:
  @uv --directory {{justfile_directory()}} sync

_write_data_release_config:
  #!/usr/bin/env python3
  import yaml
  import hcl2

  with open("{{TF_DIRECTORY}}/terraform.tfvars") as f:
      profile_tfvars = hcl2.load(f)

  with open("{{PATH_POS_YAML_CONFIG}}") as f:
      data = yaml.safe_load(f)
  data['log_level'] = profile_tfvars['pos_log_level']
  data['release_uri'] = profile_tfvars['data_location_source']
  data['scratchpad']['release'] = profile_tfvars['platform_release_version']
  data['scratchpad']['bq_parquet_path'] = profile_tfvars['data_location_production']
  
  with open("{{PATH_DATA_RELEASE_CONFIG}}", "w") as f:
      yaml.dump(data, f, default_flow_style=False)
  

# Big Query Dev
bigquerydev: _uv_sync _write_data_release_config
  @echo "BigQuery Dev"
  @uv run --directory {{justfile_directory()}} -c {{PATH_DATA_RELEASE_CONFIG}} -s bigquery_dev_load_all
  @rm {{PATH_DATA_RELEASE_CONFIG}}

# Big Query Prod
bigqueryprod: _uv_sync _write_data_release_config
  @echo "BigQuery Prod"
  @uv run --directory {{justfile_directory()}} -c {{PATH_DATA_RELEASE_CONFIG}} -s bigquery_prod_load_all
  @rm {{PATH_DATA_RELEASE_CONFIG}}	