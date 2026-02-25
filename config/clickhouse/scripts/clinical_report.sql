create table if not exists clinical_report engine = EmbeddedRocksDB () primary key id as (
    select *
    from clinical_report_log
);
drop table clinical_report_log;
