create database if not exists ot;

create table if not exists ot.disease_log (
    id LowCardinality (String),
    name LowCardinality (String),
    therapeuticAreas Array (LowCardinality (String)),
    description Nullable (String),
    dbXRefs Array (String),
    directLocationIds Array (LowCardinality (String)),
    indirectLocationIds Array (LowCardinality (String)),
    obsoleteTerms Array (LowCardinality (String)),
    synonyms Array (
        Tuple (
            relation LowCardinality (String),
            terms Array (LowCardinality (String))
        )
    ),
    parents Array (LowCardinality (String)),
    children Array (LowCardinality (String)),
    ancestors Array (LowCardinality (String)),
    descendants Array (LowCardinality (String)),
    ontology Tuple (isTherapeuticArea Boolean)
) engine = Log;