# Data prep task

from typing import Self
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearchInstanceManager


class OpenSearchRestoreError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchRestoreSpec(Spec):
    """Configuration fields for the restore OpenSearch task."""

    service_name: str = "os-pos"
    host: str = "localhost"
    port: int = 9200
    snapshot_repository_name: str
    snapshot_name: str
    indices: str = "-.*"


class OpenSearchRestore(Task):
    def __init__(self, spec: OpenSearchRestoreSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchRestoreSpec

    @report
    def run(self) -> Self:
        print("opensearch restore run")
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        opensearch.client.snapshot.restore(
            self.spec.snapshot_repository_name,
            self.spec.snapshot_name,
            body={
                "indices": self.spec.indices,
                "ignore_unavailable": True,
                "include_global_state": False,
                "ignore_index_settings": ["index.refresh_interval"],
            },
            error_trace=True,
            wait_for_completion=True,
        )
        return self
