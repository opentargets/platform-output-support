CREATE TABLE IF NOT EXISTS sequence_ontology_log (
    id LowCardinality (String),
    label LowCardinality (String)
) ENGINE = Log;