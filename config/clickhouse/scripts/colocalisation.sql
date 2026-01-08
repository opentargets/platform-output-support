create table if not exists colocalisation_left engine = MergeTree ()
order by (otherStudyType, studyLocusId) as
select
    studyLocusId,
    otherStudyLocusId,
    otherStudyType,
    chromosome,
    colocalisationMethod,
    numberColocalisingVariants,
    h3,
    h4,
    clpp,
    betaRatioSignAverage
from (
        select
            leftStudyLocusId as studyLocusId, rightStudyLocusId as otherStudyLocusId, rightStudyType as otherStudyType, chromosome, colocalisationMethod, numberColocalisingVariants, h3, h4, clpp, betaRatioSignAverage
        from colocalisation_log
    ) as left_colocs;

create table if not exists colocalisation_right engine = MergeTree ()
order by (otherStudyType, studyLocusId) as
select
    studyLocusId,
    otherStudyLocusId,
    otherStudyType,
    chromosome,
    colocalisationMethod,
    numberColocalisingVariants,
    h3,
    h4,
    clpp,
    betaRatioSignAverage
from (
        select
            rightStudyLocusId as studyLocusId, leftStudyLocusId as otherStudyLocusId, 'gwas' as otherStudyType, chromosome, colocalisationMethod, numberColocalisingVariants, h3, h4, clpp, betaRatioSignAverage
        from colocalisation_log
    ) as right_colocs;

create table if not exists colocalisation engine = MergeTree ()
order by (otherStudyType, studyLocusId) as
select *
from (
        select *
        from colocalisation_left
        union all
        select *
        from colocalisation_right
    );

drop table colocalisation_log;