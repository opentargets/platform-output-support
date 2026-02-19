CREATE TABLE IF NOT EXISTS drug ENGINE = EmbeddedRocksDB () PRIMARY KEY id AS (
    SELECT *
    FROM drug_log
);

DROP TABLE IF EXISTS drug_log SYNC;