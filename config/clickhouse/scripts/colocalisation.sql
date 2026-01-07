create table if not exists colocalisation engine = MergeTree ()
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
    ), (
        select
            rightStudyLocusId as studyLocusId, leftStudyLocusId as otherStudyLocusId, 'gwas' as otherStudyType, chromosome, colocalisationMethod, numberColocalisingVariants, h3, h4, clpp, betaRatioSignAverage
        from colocalisation_log
    );

drop table colocalisation_log;