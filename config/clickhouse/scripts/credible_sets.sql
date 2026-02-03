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

CREATE TABLE IF NOT EXISTS credible_sets_locus ENGINE = MergeTree
ORDER BY (studyLocusId, variantId) AS (
        SELECT
            studyLocusId, locus.variantId as variantId, locus.is95CredibleSet as is95CredibleSet, locus.is99CredibleSet as is99CredibleSet, locus.logBF as logBF, locus.posteriorProbability as posteriorProbability, locus.pValueMantissa as pValueMantissa, locus.pValueExponent as pValueExponent, locus.beta as beta, locus.standardError as standardError, locus.r2Overall as r2Overall
        FROM credible_sets_log ARRAY
            JOIN locus
    );