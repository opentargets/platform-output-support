create database if not exists ot;
create table if not exists ot.target_engine_log(
    targetid String,
    isInMembrane Nullable(Float64),
    isSecreted Nullable(Float64),
    hasPocket Nullable(Float64),
    hasLigand Nullable(Float64),
    geneticConstraint Nullable(Float64),
    paralogMaxIdentityPercentage Nullable(Float64),
    mouseOrthologMaxIdentityPercentage Nullable(Float64),
    isCancerDriverGene Nullable(Float64),
    hasTEP Nullable(Float64),
    hasMouseKO Nullable(Float64),
    hasHighQualityChemicalProbes Nullable(Float64),
    maxClinicalTrialPhase Nullable(Float64),
    tissueSpecificity Nullable(Float64),
    tissueDistribution Nullable(Float64)
) engine = Log;