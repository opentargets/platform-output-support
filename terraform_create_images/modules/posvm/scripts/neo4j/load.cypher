CREATE CONSTRAINT targetID IF NOT exists
ON (t:Target)
ASSERT t.tid IS UNIQUE;

CREATE CONSTRAINT diseaseID IF NOT exists
ON (d:Disease)
ASSERT d.did IS UNIQUE;

CREATE CONSTRAINT tltID IF NOT exists
ON (t:PathwayTopLevelTerm)
ASSERT t.name IS UNIQUE;

CREATE CONSTRAINT targetClassID IF NOT exists
ON (t:TargetClass)
ASSERT t.name IS UNIQUE;

CREATE CONSTRAINT targetTractabilityId IF NOT exists
ON (t:TargetTractability)
ASSERT t.name IS UNIQUE;

CREATE INDEX TargetId IF NOT exists
FOR (n:Target)
ON (n.tid);

CREATE INDEX DiseaseId IF NOT exists
FOR (d:Disease)
ON (d.did);