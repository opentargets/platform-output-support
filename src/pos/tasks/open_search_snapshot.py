# Data prep task

from typing import Self

from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError
from otter.validators import v

from pos.opensearch.service import OpenSearchInstanceManager, SnapshotRepository


class OpenSearchSnapshotError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchSnapshotSpec(Spec):
    """Configuration fields for the Snapshot OpenSearch task."""

    service_name: str = 'os-pos'
    host: str = 'localhost'
    port: str = '9200'
    snapshot_repository_name: str
    snapshot_name: str
    snapshot_bucket: str
    snapshot_base_path: str
    indices: str = '*,-.*'


class OpenSearchSnapshot(Task):
    def __init__(self, spec: OpenSearchSnapshotSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchSnapshotSpec

    @report
    def run(self) -> Self:
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        snapshot_repo = SnapshotRepository(
            name=self.spec.snapshot_repository_name,
            type='gcs',
            bucket=self.spec.snapshot_bucket,
            base_path=self.spec.snapshot_base_path,
        )
        opensearch.client.snapshot.create_repository(snapshot_repo.name, snapshot_repo.body())
        opensearch.client.snapshot.create(
            self.spec.snapshot_repository_name,
            self.spec.snapshot_name,
            body={
                'indices': self.spec.indices,
                'ignore_unavailable': True,
                'include_global_state': False,
            },
            wait_for_completion=True,
        )
        return self
