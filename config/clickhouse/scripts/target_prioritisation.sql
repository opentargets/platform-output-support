CREATE TABLE IF NOT EXISTS target_prioritisation ENGINE = EmbeddedRocksDB () primary key targetId as (
    SELECT
        targetId,
        arrayFilter(x -> x.2 != '', [
        ('geneticConstraint', toString(geneticConstraint)),
        ('hasHighQualityChemicalProbes', toString(hasHighQualityChemicalProbes)),
        ('hasLigand', toString(hasLigand)),
        ('hasPocket', toString(hasPocket)),
        ('hasSafetyEvent', toString(hasSafetyEvent)),
        ('hasSmallMoleculeBinder', toString(hasSmallMoleculeBinder)),
        ('hasTEP', toString(hasTEP)),
        ('isCancerDriverGene', toString(isCancerDriverGene)),
        ('isInMembrane', toString(isInMembrane)),
        ('isSecreted', toString(isSecreted)),
        ('maxClinicalTrialPhase', toString(maxClinicalTrialPhase)),
        ('mouseKOScore', toString(mouseKOScore)),
        ('mouseOrthologMaxIdentityPercentage', toString(mouseOrthologMaxIdentityPercentage)),
        ('paralogMaxIdentityPercentage', toString(paralogMaxIdentityPercentage)),
        ('tissueDistribution', toString(tissueDistribution)),
        ('tissueSpecificity', toString(tissueSpecificity)),
        ('geneEssentiality', if(isEssential, "-1", "0"))
    ])::Array(Tuple(key String, value String)) AS targetPrioritisation
    FROM target_prioritisation_log
    LEFT OUTER JOIN target_essentiality ON target_prioritisation_log.targetId = target_essentiality.id
);

DROP TABLE IF EXISTS target_prioritisation_log SYNC;