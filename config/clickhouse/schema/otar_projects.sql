CREATE TABLE IF NOT EXISTS otar_projects_log (
    efo_id String,
    projects Array (
        Tuple (
            otar_code String,
            status Nullable (String),
            project_name Nullable (String),
            reference String,
            integrates_data_PPP Nullable (Bool)
        )
    )
) ENGINE = Log;