CREATE TABLE IF NOT EXISTS disease_hpo_log (
    phenotype String,
    disease String,
    evidence Array (
        Tuple (
            aspect Nullable (String),
            bioCuration Nullable (String),
            diseaseFromSourceId String,
            diseaseFromSource String,
            diseaseName String,
            evidenceType Nullable (String),
            frequency Nullable (String),
            modifiers Array (String),
            onset Array (String),
            qualifierNot Bool,
            references Array (String),
            sex Nullable (String),
            resource String
        )
    )
) ENGINE = Log;