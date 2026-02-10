CREATE TABLE IF NOT EXISTS biosample ENGINE = EmbeddedRocksDB () PRIMARY KEY biosampleId AS (
    SELECT *
    FROM biosample_log
);

DROP TABLE IF EXISTS biosample_log SYNC;