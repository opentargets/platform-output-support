create table if not exists intervals engine = MergeTree ()
order by (chromosome, start, end) as (
        select *
        from intervals_log
    );

drop table intervals_log SYNC;