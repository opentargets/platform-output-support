CREATE TABLE IF NOT EXISTS indication_log (
    id String,
    indications Array (
        Tuple (
            maxPhaseForIndication Float32,
            disease String,
            references Array (
                Tuple (
                    ids Array (String),
                    source LowCardinality (String)
                )
            )
        )
    ),
    indicationCount UInt8,
    approvedIndications Array (String)
) engine = Log;