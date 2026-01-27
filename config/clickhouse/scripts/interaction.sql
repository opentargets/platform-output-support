CREATE TABLE IF NOT EXISTS interaction ENGINE = MergeTree
ORDER BY (
        targetA,
        sourceDatabase,
        scoring
    ) SETTINGS allow_nullable_key = 1 AS (
        SELECT *
        FROM interaction_log
    );

DROP TABLE IF EXISTS interaction_log;