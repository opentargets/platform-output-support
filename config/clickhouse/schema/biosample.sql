CREATE TABLE IF NOT EXISTS biosample_log (
    biosampleId String,
    biosampleName String,
    description Nullable (String),
    xrefs Array (String),
    synonyms Array (String),
    parents Array (String),
    ancestors Array (String),
    children Array (String),
    descendants Array (String)
) ENGINE = Log;