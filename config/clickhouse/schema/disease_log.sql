create database if not exists ot;
drop table ot.disease_log2;
CREATE TABLE if not exists ot.disease_log2 
(  
    id String,
	code String,
	name String,
    description String,
    dbXRefs Array(String),
    parents Array(String),
    synonyms Tuple
    (
        hasExactSynonym Array(String),
	    hasRelatedSynonym Array(String),
	    hasNarrowSynonym Array(String),
	    hasBroadSynonym Array(String)
    ),
    obsoleteTerms Array(String),
    obsoleteXRefs Array(Nullable(String)),
    children Array(String),
    ancestors Array(String),
    therapeuticAreas Array(String),
    descendants Array(String),
    ontology Tuple
    (
        isTherapeuticArea Bool,
	    leaf Bool,
	    sources Tuple
        (
            url String,
	        name String
        )
    )
) engine = Log;