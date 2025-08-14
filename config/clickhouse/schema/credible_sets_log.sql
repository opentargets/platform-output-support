create database if not exists ot;

CREATE TABLE if not exists ot.credible_sets_log (
    `studyLocusId` String,
    `variantId` Nullable (String),
    `chromosome` Nullable (
        Enum(
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            '16',
            '17',
            '18',
            '19',
            '20',
            '21',
            '22',
            'X',
            'Y',
            'MT'
        )
    ),
    `position` Nullable (UInt32),
    `region` Nullable (String),
    `studyId` Nullable (String),
    `beta` Nullable (Float64),
    `zScore` Nullable (Float64),
    `pValueMantissa` Nullable (Float64),
    `pValueExponent` Nullable (Int32),
    `effectAlleleFrequencyFromSource` Nullable (Float64),
    `standardError` Nullable (Float64),
    `subStudyDescription` Nullable (String),
    `qualityControls` Array (String),
    `finemappingMethod` Nullable (String),
    `credibleSetIndex` Nullable (UInt32),
    `credibleSetlog10BF` Nullable (Float64),
    `purityMeanR2` Nullable (Float64),
    `purityMinR2` Nullable (Float64),
    `locusStart` Nullable (Int32),
    `locusEnd` Nullable (Int32),
    `sampleSize` Nullable (UInt32),
    `ldSet` Array (
        Tuple (
            `tagVariantId` Nullable (String),
            `r2Overall` Nullable (Float64)
        )
    ),
    `studyType` Nullable (
        Enum(
            'tuqtl',
            'pqtl',
            'eqtl',
            'sqtl',
            'sctuqtl',
            'scpqtl',
            'sceqtl',
            'scsqtl',
            'gwas'
        )
    ),
    `qtlGeneId` Nullable (String),
    `confidence` Nullable (String),
    `isTransQtl` Nullable (Bool)
) engine = Log;