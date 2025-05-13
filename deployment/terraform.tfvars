#vm_pos_machine_type = "n1-standard-8"
#vm_pos_boot_disk_size = 60
#clickhouse_snapshot_source = "pos-20250513-1250-ch-snapshot"
#open_search_snapshot_source = "pos-20250513-1250-os-snapshot"
pos_git_branch = "3867-terraform"
platform_release_version = "25.03"
clickhouse_tarball = true
opensearch_tarball = true
# Be warned, too many logs will slow things down a lot.
pos_log_level = "ERROR"