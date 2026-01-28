create table if not exists clinical_indication_drug engine = MergeTree ()
order by (drugId, id) primary key (drugId) as
select id,
    drugId,
    diseaseId,
    maxClinicalStage,
    clinicalReportIds,
    hasExpertReview
from clinical_indication_log
where drugId is not null;
create table if not exists clinical_indication_disease engine = MergeTree ()
order by (diseaseId, id) primary key (diseaseId) as
select id,
    drugId,
    diseaseId,
    maxClinicalStage,
    clinicalReportIds,
    hasExpertReview
from clinical_indication_log
where diseaseId is not null;
drop table clinical_indication_log;
