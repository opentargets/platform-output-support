CREATE TABLE if not exists studies engine = EmbeddedRocksDB () primary key studyId as (
    select *
    from studies_log
);