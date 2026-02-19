create table if not exists clinical_indication_log (
    id String,
    drugId LowCardinality (String),
    diseaseId LowCardinality (String),
    maxClinicalStage LowCardinality (String),
    clinicalReportIds Array (String)
) engine = Log;
