CREATE TABLE IF NOT EXISTS drug_warnings_log (
    toxicityClass Nullable (String),
    chemblIds Array (String),
    country Nullable (String),
    description Nullable (String),
    id Nullable (UInt64),
    references Array (
        Tuple (
            id String,
            source String,
            url String
        )
    ),
    warningType String,
    year Nullable (UInt16),
    efoTerm Nullable (String),
    efoId Nullable (String),
    efoIdForWarningClass Nullable (String)
) ENGINE = Log;