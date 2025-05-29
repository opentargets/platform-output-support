# Platform Output Support (POS) profile.


# ==== General config ====

# Is partner preview pipeline?
is_ppp = false
# POS git branch to use
pos_git_branch = "main"
# Make a tarball of ClickHouse and OpenSearch data.
clickhouse_tarball = false
opensearch_tarball = false
# Log level for POS
# Be warned, too many logs will slow things down a lot.
pos_log_level = "ERROR"

# ==== Data release config ====

release_id = "25.06"

# Source data

data_location_source = "gs://open-targets-pipeline-runs/szsz/25.06-testrun-1"

# Production data
data_location_production = "gs://open-targets-data-releases/25.06"


# ==== VM config ====

# Custom geos for building the data backend
# vm_pos_machine_type = "n1-standard-8"
# vm_pos_boot_disk_size = 60

# ==== Snapshots ====

# Uncomment the following lines to use existing napshots for ClickHouse and OpenSearch.
# clickhouse_snapshot_source = "pos-20250513-1250-ch-snapshot"
# open_search_snapshot_source = "pos-20250513-1250-os-snapshot"