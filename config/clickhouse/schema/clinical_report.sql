create table if not exists clinical_report_log (
    id String,
    source LowCardinality (String),
    clinicalStage LowCardinality (String),
    phaseFromSource Nullable (String),
    type Nullable (String),
    trialStudyType Nullable (String),
    trialDescription Nullable (String),
    trialNumberOfArms Nullable (Int32),
    trialStartDate Nullable (Date),
    trialLiterature Array (String),
    trialOverallStatus Nullable (String),
    trialWhyStopped Nullable (String),
    trialPrimaryPurpose Nullable (String),
    trialPhase Nullable (String),
    diseases Array (
        Tuple (
            diseaseFromSource String,
            diseaseId String
        )
    ),
    drugs Array (
        Tuple (
            drugFromSource String,
            drugId String
        )
    ),
    hasExpertReview Bool,
    countries Array (String),
    year Nullable (Int32),
    sideEffects Array (
        Tuple (
            diseaseId Nullable (String),
            diseaseFromSource Nullable (String)
        )
    ),
    trialOfficialTitle Nullable (String),
    url Nullable (String)
) engine = Log;
