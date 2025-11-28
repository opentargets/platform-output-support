CREATE TABLE if not exists credible_sets engine = EmbeddedRocksDB () primary key studyLocusId as (
    select * except locus
    from credible_sets_log
);

CREATE TABLE IF NOT EXISTS credible_sets_by_study ENGINE = MergeTree ()
ORDER BY (
        studyType,
        studyId,
        studyLocusId
    ) SETTINGS allow_nullable_key = 1 AS (
        SELECT * except locus
        FROM credible_sets_log
    );

SET max_memory_usage = 600000000000;

SET max_threads = 4;

CREATE TABLE IF NOT EXISTS credible_sets_by_variant ENGINE = MergeTree ()
ORDER BY (studyType, variantId) SETTINGS allow_nullable_key = 1 AS (
        select * except (locus, variantId), arrayJoin (locus.variantId) as variantId
        from credible_sets_log
    );