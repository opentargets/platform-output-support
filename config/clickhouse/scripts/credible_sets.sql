CREATE TABLE IF NOT EXISTS credible_sets ENGINE = EmbeddedRocksDB () PRIMARY KEY studyLocusId AS (
    SELECT * except locus
    FROM credible_sets_log
);

CREATE TABLE IF NOT EXISTS credible_sets_by_study ENGINE = MergeTree
ORDER BY (studyId) AS (
        SELECT
            groupArrayDistinct (studyLocusId) AS studyLocusIds, studyId
        FROM credible_sets_log
        GROUP BY
            studyId
    );

CREATE TABLE IF NOT EXISTS credible_sets_by_variant ENGINE = MergeTree
ORDER BY (variantId) AS (
        SELECT
            groupArrayDistinct (studyLocusId) AS studyLocusIds, arrayJoin (locus.variantId) AS variantId
        FROM credible_sets_log
        GROUP BY
            variantId
    );

CREATE TABLE IF NOT EXISTS credible_sets_by_region ENGINE = MergeTree
ORDER BY (region) SETTINGS allow_nullable_key = 1 AS (
        SELECT
            groupArrayDistinct (studyLocusId) AS studyLocusIds,
            region
        FROM credible_sets_log
        WHERE
            region IS NOT NULL
        GROUP BY
            region
    );

CREATE TABLE IF NOT EXISTS credible_sets_by_study_type ENGINE = MergeTree
ORDER BY (studyType) SETTINGS allow_nullable_key = 1 AS (
        SELECT
            groupArrayDistinct (studyLocusId) AS studyLocusIds,
            studyType
        FROM credible_sets_log
        WHERE
            studyType IS NOT NULL
        GROUP BY
            studyType
    );