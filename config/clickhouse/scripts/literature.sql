create table if not exists literature_index engine = MergeTree ()
order by (
        keywordId, SHA512 (pmid), year, month, day
    ) as (
        select
            pmid, pmcid, keywordId, relevance, date, year, month, day
        from literature_log
    );

create table if not exists literature engine = MergeTree ()
order by (SHA512 (pmid)) as (
        select
            pmid, any (pmcid) as pmcid, any (date) as date, any (year) as year, any (month) as month, any (day) as day
        from literature_log
        group by
            pmid
    );

drop table literature_log;