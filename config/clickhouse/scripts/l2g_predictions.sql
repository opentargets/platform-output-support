CREATE TABLE if not exists l2g_predictions engine = MergeTree ()
ORDER BY (studyLocusId, score) AS (
        SELECT *
        FROM l2g_predictions_log
    );

DROP TABLE IF EXISTS l2g_predictions_log;