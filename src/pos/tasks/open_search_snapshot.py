# Data prep task

from loguru import logger
from typing import Self
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError
from otter.validators import v

from pos.opensearch.service import OpenSearchInstanceManager


class OpenSearchSnapshotError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchSnapshotSpec(Spec):
    """Configuration fields for the Snapshot OpenSearch task."""

    service_name: str = "os-pos"
    host: str = "localhost"
    port: int = 9200
    snapshot_repository_name: str
    snapshot_name: str
    indices: str = "*,-.*"


class OpenSearchSnapshot(Task):
    def __init__(self, spec: OpenSearchSnapshotSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchSnapshotSpec

    @report
    def run(self) -> Self:
        logger.info("opensearch snapshot run")
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        opensearch.client.snapshot.create(
            self.spec.snapshot_repository_name,
            self.spec.snapshot_name,
            body={
                "indices": self.spec.indices,
                "ignore_unavailable": True,
                "include_global_state": False,
            },
            wait_for_completion=True,
        )
        return self
