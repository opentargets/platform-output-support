# Data prep task

from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearch, SnapshotRepository


class OpenSearchSnapshotError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchSnapshotSpec(Spec):
    """Configuration fields for the Snapshot OpenSearch task.
    """
    service_name: str
    snapshot_repository_name: str
    snapshot_name: str


class OpenSearchSnapshot(Task):
    def __init__(self, spec: OpenSearchSnapshotSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchSnapshotSpec

    @report
    def run(self) -> None:
        print("opensearch snapshot run")
        opensearch = OpenSearch(
            self.spec.service_name,
        )
        opensearch.snapshot(
            SnapshotRepository(self.spec.snapshot_repository_name),
            self.spec.snapshot_name
        )
