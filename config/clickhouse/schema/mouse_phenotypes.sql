CREATE TABLE IF NOT EXISTS mouse_phenotypes_log (
    biologicalModels Array (
        Tuple (
            allelicComposition String,
            geneticBackground String,
            id Nullable (String),
            literature Array (String)
        )
    ),
    modelPhenotypeClasses Array (
        Tuple (id String, label String)
    ),
    modelPhenotypeId String,
    modelPhenotypeLabel String,
    targetFromSourceId String,
    targetInModel String,
    targetInModelEnsemblId Nullable (String),
    targetInModelMgiId String
) engine = Log;