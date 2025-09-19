create database if not exists ot;

create table if not exists ot.baseline_expression_log (
    targetId LowCardinality(String),
    targetFromSourceId Nullable(String),
    tissueBiosampleId Nullable(String),
    tissueBiosampleFromSource Nullable(String),
    celltypeBiosampleId Nullable(String),
    celltypeBiosampleFromSource Nullable(String),
    min Float64,
    q1 Float64,
    median Float64,
    q3 Float64,
    max Float64,
    distribution_score Float64,
    specificity_score Float64,
    datasourceId String,
    datatypeId String,
    unit String,
) engine = Log;
