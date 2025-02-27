# Data prep task

from typing import Self
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearchInstanceManager


class OpenSearchCreateIndexError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchCreateIndexSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str = "os-pos"
    host: str = "localhost"
    port: int = 9200
    index: str
    mappings: str


class OpenSearchCreateIndex(Task):
    def __init__(self, spec: OpenSearchCreateIndexSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchCreateIndexSpec

    @report
    def run(self) -> Self:
        print("opensearch create index run")
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        with open(self.spec.mappings, "r") as f:
            opensearch.client.indices.create(
                index=self.spec.index,
                body=f.read(),
            )
        return self
