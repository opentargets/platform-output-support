CREATE TABLE IF NOT EXISTS reactome ENGINE = EmbeddedRocksDB () PRIMARY KEY id AS (
    SELECT *
    FROM reactome_log
);

DROP TABLE IF EXISTS reactome_log SYNC;