# Open Targets: Create ES and CH images

This module uses the output of ETL to generate the Elasticsearch and Clickhouse images.

It should not be necessary to update anything in this file directly. To create the images use the `Makefile` at the repository root. This document is a brief overview of the structure of this module.

This module is composed of three units: `posvm`, `clickhouse`, and `elasticsearch`.

## POSVM

This VM 'drives' the process, in that it downloads various datasets, loads Elasticsearch, and then creates the machine images which are later deployed.

The main logic is in the script `startup.sh`.

Once Elasticsearch is loaded (see `load_all_data.sh`) and Clickhouse has a tag indicating it has completed all of its processes, POSVM will stop each machine and  then create machine images.

## Clickhouse

- Installs a local instance of the Clickhouse database.
- Downloads SQL scripts from the _main_ branch of this repository on github. (Note that if you make changes locally they won't be propagated until they are merged into the _main_ branch.)
- Loads ETL outputs (`AOTFClickhouse`, `vectors`, `literatureIndex`) from Google storage and inserts them into Clickhouse. (Caution: there is no retry or error handling logic!)
- When data loading is completed, adds a tag to the machine. This tag is used by POSVM to recognise that the Clickhouse VM can be shut down and a machine image can be made.

## Elasticsearch

- Starts an Elasticsearch Docker container. Data is loaded into this container by POSVM. When loading is complete, POSVM will shut this machine down and make an image which be deployed using the `terraform-google-opentargets-platform` repository.

## Logs

The logs for these processes can be found by creating an ssh tunnel in to the machine of interest, and then querying the startup script logs:

```bash
# ssh into machine: update zone, machine, project as necessary
gcloud compute ssh --zone "europe-west1-d" "posprod-vm-support-vm-6h3ur4de"  --project "open-targets-eu-dev"
# view logs
sudo journalctl -u google-startup-scripts.service -f
```
