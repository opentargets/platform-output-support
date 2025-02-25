# Data prep task

from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearch


class OpenSearchCreateIndexError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchCreateIndexSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str
    index: str
    mappings: str


class OpenSearchCreateIndex(Task):
    def __init__(self, spec: OpenSearchCreateIndexSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchCreateIndexSpec

    @report
    def run(self) -> None:
        print("opensearch create index run")
        opensearch = OpenSearch(
            self.spec.service_name,
        )
        opensearch.create_index(self.spec.index, self.spec.mappings)
