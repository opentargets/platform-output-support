CREATE TABLE IF NOT EXISTS drug_warnings_log (
    toxicityClass Nullable (String),
    chemblIds Array (String),
    country Nullable (String),
    description Nullable (String),
    id Nullable (UInt64),
    references Array (
        Tuple (
            ref_id String,
            ref_type String,
            ref_url String
        )
    ),
    warningType String,
    year Nullable (UInt16),
    efo_term Nullable (String),
    efo_id Nullable (String),
    efo_id_for_warning_class Nullable (String)
) ENGINE = Log;