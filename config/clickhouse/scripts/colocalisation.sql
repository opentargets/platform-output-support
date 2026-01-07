create table if not exists colocalisation_left engine = MergeTree ()
order by (rightStudyType, studyLocusId) as
select
    studyLocusId,
    otherStudyLocusId,
    rightStudyType,
    chromosome,
    colocalisationMethod,
    numberColocalisingVariants,
    h3,
    h4,
    clpp,
    betaRatioSignAverage
from (
        select
            leftStudyLocusId as studyLocusId, rightStudyLocusId as otherStudyLocusId, rightStudyType, chromosome, colocalisationMethod, numberColocalisingVariants, h3, h4, clpp, betaRatioSignAverage
        from colocalisation_log
    ) as left_colocs;

create table if not exists colocalisation_right engine = MergeTree ()
order by (rightStudyType, studyLocusId) as
select
    studyLocusId,
    otherStudyLocusId,
    rightStudyType,
    chromosome,
    colocalisationMethod,
    numberColocalisingVariants,
    h3,
    h4,
    clpp,
    betaRatioSignAverage
from (
        select
            rightStudyLocusId as studyLocusId, leftStudyLocusId as otherStudyLocusId, 'gwas' as rightStudyType, chromosome, colocalisationMethod, numberColocalisingVariants, h3, h4, clpp, betaRatioSignAverage
        from colocalisation_log
    ) as right_colocs;

create table if not exists colocalisation engine = MergeTree ()
order by (rightStudyType, studyLocusId) as
select *
from (
        select *
        from colocalisation_left
        union all
        select *
        from colocalisation_right
    );

drop table colocalisation_log;

drop table colocalisation_left;

drop table colocalisation_right;