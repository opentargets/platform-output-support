CREATE TABLE if not exists interaction_evidence_log (
    evidenceScore Nullable (Float64),
    expansionMethodMiIdentifier Nullable (String),
    expansionMethodShortName Nullable (String),
    hostOrganismScientificName Nullable (String),
    hostOrganismTaxId Nullable (UInt32),
    hostOrganismTissue Tuple (
        fullName Nullable (String),
        shortName Nullable (String),
        xrefs Array (
            Tuple (
                database LowCardinality (String),
                identifier LowCardinality (String)
            )
        )
    ),
    interactionDetectionMethodMiIdentifier String,
    interactionDetectionMethodShortName String,
    interactionIdentifier Nullable (String),
    interactionResources Tuple (
        databaseVersion LowCardinality (String),
        sourceDatabase LowCardinality (String)
    ),
    interactionScore Float64,
    interactionTypeMiIdentifier Nullable (String),
    interactionTypeShortName Nullable (String),
    intA String,
    intABiologicalRole LowCardinality (String),
    intASource String,
    intB String,
    intBBiologicalRole LowCardinality (String),
    intBSource String,
    speciesA Tuple (
        mnemonic LowCardinality (String),
        scientificName LowCardinality (String),
        taxonId UInt8
    ),
    speciesB Tuple (
        mnemonic LowCardinality (String),
        scientificName LowCardinality (Nullable (String)),
        taxonId Nullable (UInt8)
    ),
    targetA String,
    targetB String,
    participantDetectionMethodA Array (
        Tuple (
            miIdentifier Nullable (String),
            shortName Nullable (String)
        )
    ),
    participantDetectionMethodB Array (
        Tuple (
            miIdentifier Nullable (String),
            shortName Nullable (String)
        )
    ),
    pubmedId Nullable (String)
) engine = Log;