create database if not exists ot;

CREATE TABLE if not exists ot.targets_log (
    `id` String,
    `alternativeGenes` Array (String),
    `approvedSymbol` String,
    `approvedName` String,
    `biotype` String,
    `chemicalProbes` Array (
        Tuple (
            `id` String,
            `control` Nullable (String),
            `drugId` Nullable (String),
            `mechanismOfAction` Array (String),
            `isHighQuality` Bool,
            `origin` Array (String),
            `probeMinerScore` Nullable (Float64),
            `probesDrugsScore` Nullable (Float64),
            `scoreInCells` Nullable (Float64),
            `scoreInOrganisms` Nullable (Float64),
            `targetFromSourceId` String,
            `urls` Array (
                Tuple (
                    `niceName` String,
                    `url` Nullable (String)
                )
            )
        )
    ),
    `dbXrefs` Array (
        Tuple (`id` String, `source` String)
    ),
    `functionDescriptions` Array (String),
    `constraint` Array (
        Tuple (
            `constraintType` String,
            `exp` Nullable (Float64),
            `obs` Nullable (UInt32),
            `oe` Nullable (Float64),
            `oeLower` Nullable (Float64),
            `oeUpper` Nullable (Float64),
            `score` Nullable (Float64),
            `upperBin` Nullable (UInt32),
            `upperBin6` Nullable (UInt32),
            `upperRank` Nullable (UInt32)
        )
    ),
    `genomicLocation` Tuple (
        -- `chromosome` Enum(
        --     '1',
        --     '2',
        --     '3',
        --     '4',
        --     '5',
        --     '6',
        --     '7',
        --     '8',
        --     '9',
        --     '10',
        --     '11',
        --     '12',
        --     '13',
        --     '14',
        --     '15',
        --     '16',
        --     '17',
        --     '18',
        --     '19',
        --     '20',
        --     '21',
        --     '22',
        --     'X',
        --     'Y',
        --     'MT'
        -- ),
        `chromosome` LowCardinality (String),
        `start` UInt32,
        `end` UInt32,
        `strand` UInt8
    ),
    `go` Array (
        Tuple (
            `id` String,
            `aspect` String,
            `evidence` String,
            `geneProduct` String,
            `source` String
        )
    ),
    `hallmarks` Tuple (
        `cancerHallmarks` Array (
            Tuple (
                `description` String,
                `impact` Nullable (String),
                `label` String,
                `pmid` UInt32,
            )
        ),
        `attributes` Array (
            Tuple (
                `name` String,
                `description` String,
                `pmid` Nullable (UInt32)
            )
        )
    ),
    `homologues` Array (
        Tuple (
            `homologueType` String,
            `queryPercentageIdentity` Float64,
            `speciesId` String,
            `speciesName` String,
            `targetGeneId` String,
            `targetGeneSymbol` String,
            `targetPercentageIdentity` Float64,
            `isHighConfidence` Nullable (String)
        )
    ),
    `pathways` Array (
        Tuple (
            `pathway` String,
            `pathwayId` String,
            `topLevelTerm` String
        )
    ),
    `proteinIds` Array (
        Tuple (`id` String, `source` String,)
    ),
    `safetyLiabilities` Array (
        Tuple (
            `bisamples` Array (
                Tuple (
                    `tissueLabel` Nullable (String),
                    `tissueId` Nullable (String),
                    `cellLabel` Nullable (String),
                    `cellFormat` Nullable (String),
                    `cellId` Nullable (String)
                )
            ),
            `datasource` String,
            `effects` Array (
                Tuple (
                    `direction` String,
                    `dosing` Nullable (String)
                )
            ),
            `event` Nullable (String),
            `eventId` Nullable (String),
            `literature` Nullable (String),
            `url` Nullable (String),
            `studies` Array (
                Tuple (
                    `name` Nullable (String),
                    `description` Nullable (String),
                    `type` Nullable (String)
                )
            )
        )
    ),
    `subcellularLocations` Array (
        Tuple (
            `location` String,
            `source` String,
            `termSL` Nullable (String),
            `labelSL` Nullable (String)
        )
    ),
    `synonyms` Array (
        Tuple (
            `label` String,
            `source` String
        )
    ),
    `symbolSynonyms` Array (
        Tuple (
            `label` String,
            `source` String
        )
    ),
    `nameSynonyms` Array (
        Tuple (
            `label` String,
            `source` String
        )
    ),
    `obsoleteSymbols` Array (
        Tuple (
            `label` String,
            `source` String
        )
    ),
    `obsoleteNames` Array (
        Tuple (
            `label` String,
            `source` String
        )
    ),
    `targetClass` Array (
        Tuple (
            `id` UInt32,
            `label` String,
            `level` String
        )
    ),
    `tep` Tuple (
        `url` String,
        `targetFromSourceId` String,
        `therapeuticArea` String,
        `description` String
    ),
    `tractability` Array (
        Tuple (
            `id` String,
            `modality` String,
            `value` Boolean
        )
    ),
    `transcriptIds` Array (String)
) engine = Log;