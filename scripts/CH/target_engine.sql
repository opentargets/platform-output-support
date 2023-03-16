create database if not exists ot;
create table if not exists ot.target_engine
    engine = MergeTree()
        order by (targetid)
        primary key (targetid)
as
select targetid,
    isInMembrane,
    isSecreted,
    hasPocket,
    hasLigand,
    geneticConstraint,
    paralogMaxIdentityPercentage,
    mouseOrthologMaxIdentityPercentage,
    isCancerDriverGene,
    hasTEP,
    hasMouseKO,
    hasHighQualityChemicalProbes,
    maxClinicalTrialPhase,
    tissueSpecificity,
    tissueDistribution
from ot.ml_w2v_log;
