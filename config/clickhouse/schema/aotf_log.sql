create database if not exists ot;

create table if not exists ot.associations_otf_log (
    row_id String,
    disease_id String,
    target_id String,
    disease_data Nullable (String),
    target_data Nullable (String),
    datasource_id String,
    datatype_id String,
    row_score Float64
) engine = Log;
