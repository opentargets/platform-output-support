neo4j-admin import \
  --database=neo4j \
  --nodes=Target="import/headers/targets-header.csv,import/data/targets/part.*" \
  --nodes=Disease="import/headers/diseases-header.csv,import/data/diseases/part.*" \
  --nodes=PathwayTopLevelTerm="import/headers/pathway-tlt-header.csv,import/data/pathwayNode/part.*" \
  --nodes=TargetClass="import/headers/class-header.csv,import/data/targetClassNodes/part.*" \
  --nodes=TherapeuticArea="import/headers/therapeutic-area-header.csv,import/data/therapeuticAreaNodes/part.*" \
  --nodes=TargetTractability="import/headers/tractability-header.csv,import/data/tractabilityNodes/part.*" \
  --relationships=EVIDENCE="import/headers/evidence-header.csv,import/data/evidences/part.*" \
  --relationships=PATHWAY="import/headers/pathway-relation-header.csv,import/data/pathwayEdges/part.*" \
  --relationships=EDGE="import/headers/class-relation-header.csv,import/data/targetClassEdges/part.*" \
  --relationships=EXHIBITS="import/headers/ta-relation-header.csv,import/data/therapeuticAreaEdges/part.*" \
  --relationships=EDGE="import/headers/tractability-relation-header.csv,import/data/tractabilityEdges/part.*" \
  --relationships=DESCENDANT_OF="import/headers/disease-descendant-header.csv,import/data/diseasesDescendant/part.*" \
  --skip-bad-relationships=true \
  --legacy-style-quoting=true \

test -f /var/lib/neo4j/import.report && echo "Bad record count: $(wc -l /var/lib/neo4j/import.report)"