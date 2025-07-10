create database if not exists ot;
create table if not exists ot.disease engine = MergeTree ()
order by
    id as 
    (
        select id, code, name, description, dbXRefs, parents, synonyms, obsoleteTerms, obsoleteXRefs, children, ancestors, therapeuticAreas, descendants, ontology.isTherapeuticArea from ot.disease_log2
    );

drop table ot.disease_log;
