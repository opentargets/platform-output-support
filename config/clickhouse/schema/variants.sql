-- case class VariantEffect(method: Option[String],
--                          assessment: Option[String],
--                          score: Option[Double],
--                          assessmentFlag: Option[String],
--                          targetId: Option[String],
--                          normalisedScore: Option[Double]
-- )

-- case class TranscriptConsequence(variantFunctionalConsequenceIds: Option[Seq[String]],
--                                  aminoAcidChange: Option[String],
--                                  uniprotAccessions: Option[Seq[String]],
--                                  isEnsemblCanonical: Boolean,
--                                  codons: Option[String],
--                                  distanceFromFootprint: Int,
--                                  distanceFromTss: Int,
--                                  targetId: Option[String],
--                                  impact: Option[String],
--                                  transcriptId: Option[String],
--                                  lofteePrediction: Option[String],
--                                  siftPrediction: Option[Double],
--                                  polyphenPrediction: Option[Double],
--                                  transcriptIndex: Long,
--                                  consequenceScore: Double
-- )

-- case class DbXref(id: Option[String], source: Option[String])

-- case class AlleleFrequency(populationName: Option[String], alleleFrequency: Option[Double])

-- case class VariantIndex(variantId: String,
--                         chromosome: String,
--                         position: Int,
--                         referenceAllele: String,
--                         alternateAllele: String,
--                         variantEffect: Option[Seq[VariantEffect]],
--                         mostSevereConsequenceId: String,
--                         transcriptConsequences: Option[Seq[TranscriptConsequence]],
--                         rsIds: Option[Seq[String]],
--                         dbXrefs: Option[Seq[DbXref]],
--                         alleleFrequencies: Option[Seq[AlleleFrequency]],
--                         hgvsId: Option[String],
--                         variantDescription: String
-- )

CREATE TABLE if not exists variants_log (
    `variantId` String,
    `chromosome` Nullable (
        Enum(
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            '16',
            '17',
            '18',
            '19',
            '20',
            '21',
            '22',
            'X',
            'Y',
            'MT'
        )
    ),
    `position` Nullable (UInt32),
    `referenceAllele` Nullable (String),
    `alternateAllele` Nullable (String),
    `mostSevereConsequenceId` Nullable (String),
    `rsIds` Array (String),
    `hgvsId` Nullable (String),
    `variantDescription` Nullable (String),
    `variantEffects` Array (
        Tuple (
            `method` Nullable (String),
            `assessment` Nullable (String),
            `score` Nullable (Float64),
            `assessmentFlag` Nullable (String),
            `targetId` Nullable (String),
            `normalisedScore` Nullable (Float64)
        )
    ),
    `transcriptConsequences` Array (
        Tuple (
            `variantFunctionalConsequenceIds` Array (String),
            `aminoAcidChange` Nullable (String),
            `uniprotAccessions` Array (String),
            `isEnsemblCanonical` Bool,
            `codons` Nullable (String),
            `distanceFromFootprint` Int32,
            `distanceFromTss` Int32,
            `targetId` Nullable (String),
            `impact` Nullable (String),
            `transcriptId` Nullable (String),
            `lofteePrediction` Nullable (String),
            `siftPrediction` Nullable (Float64),
            `polyphenPrediction` Nullable (Float64),
            `transcriptIndex` UInt32,
            `consequenceScore` Float64
        )
    ),
    `dbXrefs` Array (
        Tuple (
            `id` Nullable (String),
            `source` Nullable (String)
        )
    ),
    `alleleFrequencies` Array (
        Tuple (
            `populationName` Nullable (String),
            `alleleFrequency` Nullable (Float64)
        )
    )
);