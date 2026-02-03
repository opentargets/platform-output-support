CREATE TABLE IF NOT EXISTS credible_sets ENGINE = EmbeddedRocksDB () PRIMARY KEY studyLocusId AS (
    SELECT * except locus
    FROM credible_sets_log
);

CREATE TABLE IF NOT EXISTS credible_sets_by_study ENGINE = EmbeddedRocksDB () PRIMARY KEY studyId AS (
    SELECT
        studyId,
        groupArrayDistinct (studyLocusId) AS studyLocusIds
    FROM credible_sets_log
    WHERE
        studyId IS NOT NULL
    GROUP BY
        studyId
);

CREATE TABLE IF NOT EXISTS credible_sets_by_variant ENGINE = EmbeddedRocksDB () PRIMARY KEY variantId AS (
    SELECT
        arrayJoin (locus.variantId) AS variantId,
        groupArrayDistinct (studyLocusId) AS studyLocusIds
    FROM credible_sets_log
    GROUP BY
        variantId
);

CREATE TABLE IF NOT EXISTS credible_sets_by_region ENGINE = EmbeddedRocksDB () PRIMARY KEY region AS (
    SELECT
        groupArrayDistinct (studyLocusId) AS studyLocusIds,
        region
    FROM credible_sets_log
    WHERE
        region IS NOT NULL
    GROUP BY
        region
);

CREATE TABLE IF NOT EXISTS credible_sets_locus ENGINE = EmbeddedRocksDB () PRIMARY KEY studyLocusId AS (
    SELECT studyLocusId, locus
    FROM credible_sets_log
);