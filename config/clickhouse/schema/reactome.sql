CREATE TABLE IF NOT EXISTS reactome_log (
    id String,
    label String,
    children Array (String),
    parents Array (String),
    ancestors Array (String)
) ENGINE = Log;