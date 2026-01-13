CREATE TABLE if not exists disease_log (
    `id` String,
    `name` String,
    `therapeuticAreas` Array (LowCardinality (String)),
    `description` Nullable (String),
    `dbXRefs` Array (String),
    `directLocationIds` Array (String),
    `indirectLocationIds` Array (String),
    `obsoleteTerms` Array (String),
    `synonyms` Tuple (
        `hasExactSynonym` Array (Nullable (String)),
        `hasRelatedSynonym` Array (Nullable (String)),
        `hasNarrowSynonym` Array (Nullable (String)),
        `hasBroadSynonym` Array (Nullable (String))
    ),
    `parents` Array (LowCardinality (String)),
    `children` Array (String),
    `ancestors` Array (LowCardinality (String)),
    `descendants` Array (String),
    `ontology` Tuple (isTherapeuticArea Boolean)
) engine = Log;