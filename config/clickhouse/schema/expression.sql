CREATE TABLE IF NOT EXISTS expression_log (
    id String,
    tissues Array (
        Tuple (
            anatomical_systems Array (String),
            efo_code String,
            label String,
            organs Array (String),
            protein Tuple (
                cellType Array (
                    Tuple (
                        level Int8,
                        name String,
                        reliability Bool
                    )
                ),
                level Int8,
                reliability Bool
            ),
            rna Tuple (
                level Int8,
                unit LowCardinality (String),
                value Float64,
                zscore Int32
            )
        )
    )
) ENGINE = Log;