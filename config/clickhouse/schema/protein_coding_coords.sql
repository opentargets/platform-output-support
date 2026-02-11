CREATE TABLE IF NOT EXISTS protein_coding_coords_log (
    targetId String,
    uniprotAccessions Array (String),
    aminoAcidPosition Int32,
    alternateAminoAcid LowCardinality (String),
    referenceAminoAcid LowCardinality (String),
    variantFunctionalConsequenceIds Array (String),
    variantEffect Nullable (Float32),
    variantId String,
    diseases Array (String),
    datasources Array (
        Tuple (
            datasourceCount UInt32,
            datasourceId LowCardinality (String),
            datasourceNiceName LowCardinality (String)
        )
    ),
    therapeuticAreas Array (String)
) engine = Log;