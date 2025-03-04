# Data prep task

import json
from typing import Dict, Generator, Self

from loguru import logger
from opensearchpy import helpers
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearchInstanceManager
from pos.utils import get_config


class OpenSearchLoadError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchLoadSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str = "os-pos"
    host: str = "localhost"
    port: str = "9200"
    dataset: str
    json_parent: str


class OpenSearchLoad(Task):
    def __init__(self, spec: OpenSearchLoadSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchLoadSpec
        try:
            self._config = get_config("config/datasets.yaml").opensearch
            self._index_name = self._config[self.spec.dataset]["index"]
            self._id_field = self._config[self.spec.dataset].get("id_field")
            self._output_dir = self._config[self.spec.dataset]["output_dir"]
        except AttributeError:
            raise OpenSearchLoadError(f"Unable to load config for {self.spec.dataset}")

    @report
    def run(self) -> Self:
        print("opensearch create index run")
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        for success, info in helpers.parallel_bulk(
            opensearch.client, actions=self._generate_data()
        ):
            if not success:
                logger.error(f"Failed to index document: {info}")
        opensearch.client.indices.refresh(index=self._index_name)
        return self

    # TODO: add a Counter to track the number of records read in
    # then use to validate against the number of records indexed
    def _generate_data(self) -> Generator[Dict[str, str]]:
        with open(self._get_json(self.spec.json_parent), "r") as f:
            if self._id_field:
                logger.info(f"Using {self._id_field} as the document id")
                for record in f:
                    doc = self._build_doc(
                        record,
                        json.loads(record).get(self._id_field),
                    )
                    yield doc
            else:
                logger.info("No document id field specified")
                for record in f:
                    doc = self._build_doc(record)
                    yield doc

    def _get_json(self, json_parent: str) -> str:
        return f"{json_parent}/{self._output_dir}/{self.spec.dataset}.json"

    def _build_doc(self, record: str, id: str = None) -> Dict[str, str]:
        doc = {
            "_index": self._index_name,
            "_source": record,
        }
        if id:
            doc["_id"] = id
        return doc
