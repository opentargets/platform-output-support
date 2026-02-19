CREATE TABLE IF NOT EXISTS drug_log (
    id String,
    name String,
    synonyms Array (String),
    tradeNames Array (String),
    childChemblIds Array (String),
    yearOfFirstApproval Nullable (Int32),
    drugType String,
    isApproved Nullable (Bool),
    crossReferences Array (
        Tuple (
            source String,
            ids Array (String)
        )
    ),
    parentId Nullable (String),
    maximumClinicalTrialPhase Nullable (Float32),
    hasBeenWithdrawn Bool,
    linkedDiseases Tuple (
        count Nullable (Int32),
        rows Array (String)
    ),
    linkedTargets Tuple (
        count Nullable (Int32),
        rows Array (String)
    ),
    blackBoxWarning Bool,
    description Nullable (String)
) ENGINE = Log;