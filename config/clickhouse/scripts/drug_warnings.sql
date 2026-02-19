CREATE TABLE IF NOT EXISTS drug_warnings ENGINE = EmbeddedRocksDB () PRIMARY KEY chemblId AS (
    SELECT
        arrayJoin (chemblIds) AS chemblId,
        groupArray ((
            toxicityClass,
            chemblIds,
            country,
            description,
            id,
            references,
            warningType,
            year,
            efo_term,
            efo_id,
            efo_id_for_warning_class
        )::Tuple(
            toxicityClass Nullable (String),
            chemblIds Array (String),
            country Nullable (String),
            description Nullable (String),
            id Nullable (UInt32),
            references Array (
                Tuple (
                    ref_id String,
                    ref_type String,
                    ref_url String
                )
            ),
            warningType String,
            year Nullable (UInt16),
            efo_term Nullable (String),
            efo_id Nullable (String),
            efo_id_for_warning_class Nullable (String)
            )
        ) AS drugWarnings
    FROM drug_warnings_log
    WHERE chemblIds IS NOT NULL
    GROUP BY 
        chemblId
);

DROP TABLE IF EXISTS drug_warnings_log SYNC;