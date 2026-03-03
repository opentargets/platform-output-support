CREATE TABLE IF NOT EXISTS literature ENGINE = MergeTree ()
ORDER BY (
        keywordId, year, month, relevance
    ) AS (
        SELECT
            pmid, pmcid, keywordId, relevance, date, year, month
        FROM literature_log
    );

DROP TABLE literature_log SYNC;