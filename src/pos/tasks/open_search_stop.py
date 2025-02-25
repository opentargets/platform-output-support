# Data prep task

from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearch


class OpenSearchStopError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchStopSpec(Spec):
    """Configuration fields for the Stop OpenSearch task.
    """
    service_name: str


class OpenSearchStop(Task):
    def __init__(self, spec: OpenSearchStopSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchStopSpec

    @report
    def run(self) -> None:
        print("opensearch stop run")
        opensearch = OpenSearch(
            self.spec.service_name,
        )
        opensearch.stop()
