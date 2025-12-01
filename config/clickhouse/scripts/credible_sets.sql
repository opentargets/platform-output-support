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

CREATE TABLE IF NOT EXISTS credible_sets_by_variant ENGINE = MergeTree ()
ORDER BY (variantId) AS (
        select
            groupArray (studyLocusId) as studyLocusIds, arrayJoin (locus.variantId) as variantId
        from credible_sets_log
        group by
            variantId
    );

CREATE TABLE platform2512.credible_sets_by_variant (
    `studyLocusIds` Array (String),
    `variantId` String
) ENGINE = MergeTree
ORDER BY variantId
    -- select * except A_studyLocusId
    -- from (
    --         select arrayJoin (studyLocusIds) as A_studyLocusId
    --         from credible_sets_by_variant
    --         where
    --             variantId = '5_96874071_C_T'
    --     ) as A
    --     left join credible_sets on A.A_studyLocusId = credible_sets.studyLocusId
    -- where
    --     studyType = 'sqtl'