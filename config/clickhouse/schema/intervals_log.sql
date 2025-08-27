create database if not exists ot;

CREATE TABLE if not exists ot.intervals_log (
    `chromosome` Enum8 (
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
    ),
    `start` UInt32,
    `end` UInt32,
    `geneId` String,
    `biosampleName` LowCardinality (String),
    `biosampleId` LowCardinality (String),
    `intervalType` LowCardinality (String),
    `distanceToTss` Int32,
    `score` Float64,
    `resourceScore` Array (
        Tuple (
            name LowCardinality (String),
            value Float64
        )
    ),
    `datasourceId` LowCardinality (String),
    `pmid` String,
    `studyId` String,
) engine = Log;
;