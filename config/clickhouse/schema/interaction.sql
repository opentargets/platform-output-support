CREATE TABLE if not exists interaction_log (
    intA String,
    targetA String,
    intB String,
    targetB Nullable (String),
    intABiologicalRole LowCardinality (String),
    intBBiologicalRole LowCardinality (String),
    scoring Nullable (Float64),
    count UInt8,
    sourceDatabase Enum(
        'intact',
        'reactome',
        'signor',
        'string'
    ),
    speciesA Tuple (
        mnemonic LowCardinality (String),
        scientific_name LowCardinality (String),
        taxon_id UInt8
    ),
    speciesB Tuple (
        mnemonic LowCardinality (String),
        scientific_name LowCardinality (Nullable (String)),
        taxon_id Nullable (UInt8)
    )
) engine = Log;