# Data prep task

from typing import Self
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError
from pos.utils import get_config

from pos.opensearch.service import OpenSearchInstanceManager


class OpenSearchCreateIndexError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchCreateIndexSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str = "os-pos"
    host: str = "localhost"
    port: str = "9200"
    dataset: str


class OpenSearchCreateIndex(Task):
    def __init__(self, spec: OpenSearchCreateIndexSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchCreateIndexSpec
        self._config = get_config("config/datasets.yaml").opensearch
        try:
            self._index_name = self._config[self.spec.dataset]["index"]
            self._mappings = self._config[self.spec.dataset]["mappings"]
        except AttributeError:
            raise OpenSearchCreateIndexError(
                f"Unable to load config for {self.spec.dataset}"
            )

    @report
    def run(self) -> Self:
        print("opensearch create index run")
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        with open(self._mappings, "r") as f:
            opensearch.client.indices.create(
                index=self._index_name,
                body=f.read(),
            )
        return self
