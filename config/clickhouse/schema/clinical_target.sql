create table if not exists clinical_target_log (
    id String,
    drugId LowCardinality (String),
    targetId LowCardinality (String),
    diseases Array (
        Tuple (
            diseaseFromSource String,
            diseaseId String
        )
    ),
    maxClinicalStage LowCardinality (String),
    clinicalReportIds Array (String)
) engine = Log;
