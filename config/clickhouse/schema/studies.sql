CREATE TABLE if not exists studies_log (
    `studyId` String,
    `condition` LowCardinality (Nullable (String)),
    `projectId` String,
    `studyType` Enum(
        'tuqtl',
        'pqtl',
        'eqtl',
        'sqtl',
        'sctuqtl',
        'scpqtl',
        'sceqtl',
        'scsqtl',
        'gwas'
    ),
    `traitFromSource` String,
    `geneId` Nullable (String),
    `biosampleFromSourceId` Nullable (String),
    `nSamples` Nullable (UInt32),
    `summarystatsLocation` Nullable (String),
    `hasSumstats` Nullable (Bool),
    `cohorts` Array (String),
    `initialSampleSize` Nullable (String),
    `traitFromSourceMappedIds` Array (String),
    `diseaseIds` Array (String),
    `publicationJournal` LowCardinality (Nullable (String)),
    `publicationDate` Nullable (String),
    `ldPopulationStructure` Array (
        Tuple (
            `ldPopulation` LowCardinality (String),
            `relativeSampleSize` Nullable (Float64)
        )
    ),
    `backgroundTraitFromSourceMappedIds` Array (String),
    `qualityControls` Array (String),
    `replicationSamples` Array (
        Tuple (
            `ancestry` LowCardinality (String),
            `sampleSize` UInt32
        )
    ),
    `nControls` Nullable (UInt32),
    `pubmedId` Nullable (String),
    `publicationFirstAuthor` Nullable (String),
    `publicationTitle` Nullable (String),
    `discoverySamples` Array (
        Tuple (
            `ancestry` LowCardinality (String),
            `sampleSize` UInt32
        )
    ),
    `nCases` Nullable (UInt32),
    `analysisFlags` Array (String),
    `sumstatQCValues` Array (
        Tuple (
            `QCCheckName` String,
            `QCCheckValue` Float64
        )
    )
) engine = Log;