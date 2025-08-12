create database if not exists ot;

create table if not exists ot.intervals engine = MergeTree ()
order by
    (chromosome, start, end) as (
        select
            *
        from
            ot.intervals_log
    );

drop table ot.intervals_log;
