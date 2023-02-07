create database if not exists ot;
create table if not exists ot.sentences_log(
    pmid UInt64,
    pmcid Nullable(String),
    section String,
    endInSentence UInt16,
    label Nullable(String),
    sectionEnd UInt16,
    sectionStart UInt16,
    startInSentence UInt16,
    keywordType FixedString(2),
    keywordId String
) engine = Log;