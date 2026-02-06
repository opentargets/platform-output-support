CREATE TABLE IF NOT EXISTS expression ENGINE = EmbeddedRocksDB () PRIMARY KEY id AS (
    SELECT *
    FROM expression_log
);

DROP TABLE IF EXISTS expression_log SYNC;