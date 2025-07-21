create table if not exists ot.targets
engine = MergeTree
order by (id)
as (
    select * from ot.targets_log
    left outer join (
        select
            geneId,
            studyId
        from
            ot.studies_log
    ) as studies
    on ot.targets_log.id = studies.geneId
);
