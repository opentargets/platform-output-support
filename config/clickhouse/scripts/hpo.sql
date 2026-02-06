CREATE TABLE IF NOT EXISTS hpo ENGINE = EmbeddedRocksDB () PRIMARY KEY id AS (
    SELECT *
    FROM hpo_log
);

DROP TABLE IF EXISTS hpo_log;