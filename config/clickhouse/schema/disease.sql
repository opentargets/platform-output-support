CREATE TABLE if not exists disease_log (
    `id` String,
    `therapeuticAreas` Array (LowCardinality (String)),
) engine = Log;