CREATE TABLE IF NOT EXISTS indication ENGINE = EmbeddedRocksDB () PRIMARY KEY id AS (
    SELECT *
    FROM indication_log
);

DROP TABLE IF EXISTS indication_log SYNC;