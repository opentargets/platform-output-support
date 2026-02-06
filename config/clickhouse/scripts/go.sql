CREATE TABLE IF NOT EXISTS gene_ontology ENGINE = EmbeddedRocksDB () PRIMARY KEY id AS (
    SELECT *
    FROM gene_ontology_log
);

DROP TABLE IF EXISTS gene_ontology_log;