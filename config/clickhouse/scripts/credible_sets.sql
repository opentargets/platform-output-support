CREATE TABLE if not exists credible_sets engine = EmbeddedRocksDB () primary key studyLocusId as (
    select * except locus
    from credible_sets_log
);