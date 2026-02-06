CREATE TABLE IF NOT EXISTS gene_ontology ENGINE = EmbeddedRocksDB () PRIMARY KEY id AS (
    SELECT *
    FROM go_log
);

DROP TABLE IF EXISTS go_log;