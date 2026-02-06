create table if not exists baseline_expression engine = MergeTree ()
order by (
        targetId,
        tissueBiosampleId,
        celltypeBiosampleId
    ) settings allow_nullable_key = 1 as (
        select *
        from baseline_expression_log
    );

drop table baseline_expression_log SYNC;