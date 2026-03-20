CREATE TABLE IF NOT EXISTS novelty ENGINE = MergeTree ()
ORDER BY (
        diseaseId, targetId, isDirect, aggregationValue, year
    ) SETTINGS allow_nullable_key = 1 AS
SELECT
    diseaseId,
    targetId,
    aggregationType,
    aggregationValue,
    year,
    associationScore,
    novelty,
    yearlyEvidenceCount,
    isDirect
FROM novelty_log;

OPTIMIZE TABLE novelty FINAL;

DROP TABLE novelty_log SYNC;