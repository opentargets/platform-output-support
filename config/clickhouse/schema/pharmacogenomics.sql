CREATE TABLE IF NOT EXISTS pharmacogenomics_log (
    datasourceId LowCardinality (String),
    datatypeId LowCardinality (String),
    drugs Array (
        Tuple (
            drugId LowCardinality (String),
            drugFromSource LowCardinality (String)
        )
    ),
    evidenceLevel LowCardinality (String),
    genotype Nullable (String),
    genotypeAnnotationText Nullable (String),
    genotypeId Nullable (String),
    haplotypeFromSourceId Nullable (String),
    haplotypeId Nullable (String),
    literature Array (String),
    pgxCategory LowCardinality (String),
    phenotypeFromSourceId Nullable (String),
    phenotypeText Nullable (String),
    variantAnnotation Array (
        Tuple (
            baseAlleleOrGenotype Nullable (String),
            comparisonAlleleOrGenotype Nullable (String),
            directionality Nullable (String),
            effect Nullable (String),
            effectDescription Nullable (String),
            effectType Nullable (String),
            entity Nullable (String),
            literature Nullable (String)
        )
    ),
    studyId Nullable (String),
    targetFromSourceId Nullable (String),
    variantFunctionalConsequenceId Nullable (String),
    variantRsId Nullable (String),
    variantId Nullable (String),
    isDirectTarget Bool
) engine = Log;