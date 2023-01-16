create database if not exists ot;
create table if not exists ot.sentences engine = MergeTree()
order by (keywordId, intHash64(pmid)) as (
        select pmid,
            pmcid,
            section,
            label,
            sectionEnd,
            sectionStart,
            startInSentence,
            endInSentence,
            keywordType,
            keywordId
        from ot.sentences_log
    );