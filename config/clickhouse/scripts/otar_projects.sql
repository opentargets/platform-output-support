CREATE TABLE IF NOT EXISTS otar_projects ENGINE = EmbeddedRocksDB () PRIMARY KEY efo_id AS (
    SELECT *
    FROM otar_projects_log
);