create database if not exists ot;

create table if not exists ot.baseline_expression engine = MergeTree ()
order by
    (targetId, tissueBiosampleId, celltypeBiosampleId)
settings
    allow_nullable_key = 1
as (
        select
            *
        from
            ot.baseline_expression_log
    );

drop table ot.baseline_expression_log;
