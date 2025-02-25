# Data prep task

from typing import Dict, Generator, Self

from loguru import logger
from opensearchpy import helpers
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearchInstanceManager


class OpenSearchLoadError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchLoadSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str
    index: str
    data: str


class OpenSearchLoad(Task):
    def __init__(self, spec: OpenSearchLoadSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchLoadSpec

    @report
    def run(self) -> Self:
        print("opensearch create index run")
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
        )
        for success, info in helpers.parallel_bulk(
            opensearch.client, actions=self._generate_data()
        ):
            if not success:
                logger.error(f"Failed to index document: {info}")
        opensearch.client.indices.refresh(index=self.spec.index)
        return self

    def _generate_data(self) -> Generator[Dict[str, str]]:
        with open(self.spec.data, "r") as f:
            for doc in f:
                yield {"_index": self.spec.index, "_source": doc}
