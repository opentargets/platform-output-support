create database if not exists ot;
create table if not exists ot.sentences engine = MergeTree()
order by (keywordId, SHA512(pmid)) as (
        select pmid,
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

drop table ot.sentences_log;