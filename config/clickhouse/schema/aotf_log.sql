create database if not exists ot;

create table if not exists ot.associations_otf_log (
    row_id String,
    disease_id LowCardinality (String),
    target_id LowCardinality (String),
    disease_data Nullable (String),
    target_data Nullable (String),
    datasource_id LowCardinality (String),
    datatype_id LowCardinality (String),
    row_score Float64
) engine = Log;