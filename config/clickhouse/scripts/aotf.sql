CREATE TABLE IF NOT EXISTS ot.associations_otf_indirect engine = MergeTree PRIMARY KEY row_id
ORDER BY (row_id) AS
SELECT
    row_id,
    arrayFilter (
        x -> (x > 0),
        groupArray (r.row_score)
    ) AS indirect_scores
FROM
    ot.associations_otf_log
    LEFT JOIN ot.disease_log ON associations_otf_log.disease_id = ot.disease_log.id ARRAY
    JOIN descendants
    LEFT JOIN ot.associations_otf_log AS r ON (descendants = r.disease_id)
    AND (target_id = r.target_id)
    AND (
        datasource_id = r.datasource_id
    )
GROUP BY
    row_id;

CREATE TABLE IF NOT EXISTS ot.associations_otf_disease ENGINE = MergeTree PRIMARY KEY A
ORDER BY (A, B, datasource_id) AS
SELECT
    row_id,
    disease_id AS A,
    target_id AS B,
    datatype_id,
    datasource_id,
    row_score,
    lower(disease_data) AS A_search,
    lower(target_data) AS B_search,
    indirect_scores
FROM ot.associations_otf_log
    LEFT JOIN ot.associations_otf_indirect ON row_id = ot.associations_otf_indirect.row_id;

CREATE TABLE IF NOT EXISTS ot.associations_otf_target ENGINE = MergeTree PRIMARY KEY A
ORDER BY (A, B, datasource_id) AS
SELECT
    row_id,
    target_id AS A,
    disease_id AS B,
    datatype_id,
    datasource_id,
    row_score,
    lower(target_data) AS A_search,
    lower(disease_data) AS B_search,
    indirect_scores
FROM ot.associations_otf_log
    LEFT JOIN ot.associations_otf_indirect ON row_id = ot.associations_otf_indirect.row_id;

DROP TABLE ot.associations_otf_log;

DROP TABLE ot.associations_otf_indirect;