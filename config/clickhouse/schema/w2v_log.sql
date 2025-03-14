create database if not exists ot;

create table if not exists ot.ml_w2v_log (
    category String,
    word String,
    norm Float64,
    vector Array(Float64)
) engine = Log;
