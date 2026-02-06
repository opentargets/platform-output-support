CREATE TABLE if not exists variants engine = EmbeddedRocksDB () primary key variantId as (
    select *
    from variants_log
);

DROP TABLE IF EXISTS variants_log SYNC;