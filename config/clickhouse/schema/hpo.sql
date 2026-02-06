CREATE TABLE IF NOT EXISTS hpo_log (
    id String,
    name String,
    description Nullable (String),
    namespace Array (String)
) ENGINE = Log;