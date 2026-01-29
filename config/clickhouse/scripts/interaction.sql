CREATE TABLE IF NOT EXISTS interaction ENGINE = MergeTree
ORDER BY (
        targetA,
        sourceDatabase,
        scoring
    ) SETTINGS allow_nullable_key = 1 AS (
        SELECT i.*, groupArray (
                (
                    e.evidenceScore,
                    e.expansionMethodMiIdentifier, 
                    e.expansionMethodShortName, 
                    e.hostOrganismScientificName, 
                    e.hostOrganismTaxId, 
                    e.intASource, 
                    e.intBSource, 
                    e.interactionDetectionMethodMiIdentifier, 
                    e.interactionDetectionMethodShortName, 
                    e.interactionIdentifier,
                    e.interactionResources,
                    e.interactionTypeMiIdentifier, 
                    e.interactionTypeShortName, 
                    e.participantDetectionMethodA, 
                    e.participantDetectionMethodB, 
                    e.pubmedId
                )::Tuple(
                    evidenceScore Nullable (Float64), 
                    expansionMethodMiIdentifier Nullable (String), 
                    expansionMethodShortName Nullable (String), 
                    hostOrganismScientificName Nullable (String), 
                    hostOrganismTaxId Nullable (UInt32), 
                    intASource String, 
                    intBSource String, 
                    interactionDetectionMethodMiIdentifier String, 
                    interactionDetectionMethodShortName String, 
                    interactionIdentifier Nullable (String), 
                    interactionResources Tuple (
                        databaseVersion LowCardinality (String), 
                        sourceDatabase LowCardinality (String)
                    ),
                    interactionTypeMiIdentifier Nullable (String), 
                    interactionTypeShortName Nullable (String), 
                    participantDetectionMethodA Array (Tuple (
                        miIdentifier Nullable (String), 
                        shortName Nullable (String)
                        )
                    ), 
                    participantDetectionMethodB Array (Tuple (
                        miIdentifier Nullable (String), 
                        shortName Nullable (String))
                    ), 
                    pubmedId Nullable (String)
                    )
            ) AS evidences
        FROM
            interaction_log AS i
            LEFT JOIN interaction_evidence_log AS e ON i.targetA = e.targetA
            AND i.targetB = e.targetB
            AND i.intA = e.intA
            AND i.intB = e.intB
            AND i.intABiologicalRole = e.intABiologicalRole
            AND i.intBBiologicalRole = e.intBBiologicalRole
            AND i.sourceDatabase = e.interactionResources.sourceDatabase
        GROUP BY
            i.*
    );

DROP TABLE IF EXISTS interaction_log;

DROP TABLE IF EXISTS interaction_evidence_log;