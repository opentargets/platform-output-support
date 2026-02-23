create table if not exists associations_otf_log (
    rowId String,
    diseaseId LowCardinality (String),
    targetId LowCardinality (String),
    diseaseData Nullable (String),
    targetData Nullable (String),
    datasourceId LowCardinality (String),
    datatypeId LowCardinality (String),
    rowScore Float64,
    noveltyDirect Nullable (Float64),
    noveltyIndirect Nullable (Float64)
) engine = Log;