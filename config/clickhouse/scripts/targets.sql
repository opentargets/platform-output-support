create database if not exists ot;

-- create the credible_sets table indexed by studyId
CREATE TABLE if not exists ot.credible_sets_by_study engine = MergeTree
order by (studyId) SETTINGS allow_nullable_key = 1 as (
        select studyId, studyLocusId
        from ot.credible_sets_log
        where
            studyId is not null
            and studyLocusId is not null
    );

-- create the credible_sets table indexed by geneId
-- join with credible_sets_by_study to get array(studyLocusId) for each gene
CREATE TABLE if not exists ot.credible_sets_by_gene engine = MergeTree
order by (geneId) SETTINGS allow_nullable_key = 1 as (
        select
            geneId,
            groupArrayDistinctIf (
                studyLocusId,
                studyLocusId != ''
            ) as studyLocusIds
        from ot.studies_log
            left outer join ot.credible_sets_by_study on studies_log.studyId = credible_sets_by_study.studyId
        where
            geneId is not null
            and studyLocusId is not null
        group by
            geneId
    );

-- create the targets table indexed by id
-- and join credible_sets_by_gene to get array(studyLocusIds) for each target

CREATE TABLE if not exists ot.targets engine = MergeTree
order by (id) as (
        select *
        from ot.targets_log
            left outer join ot.credible_sets_by_gene on ot.targets_log.id = ot.credible_sets_by_gene.geneId
    );

ALTER TABLE ot.targets DROP COLUMN IF EXISTS geneId;

DROP TABLE IF EXISTS ot.targets_log;

DROP TABLE IF EXISTS ot.credible_sets_by_study;

DROP TABLE IF EXISTS ot.credible_sets_by_gene;

DROP TABLE IF EXISTS ot.studies_log;

DROP TABLE IF EXISTS ot.credible_sets_log;