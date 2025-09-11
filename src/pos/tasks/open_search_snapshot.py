# Data prep task

from dataclasses import dataclass

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.opensearch import OpenSearchInstanceManager


@dataclass
class SnapshotRepository:
    """Snapshot repository configuration fields.

    Args:
        name: Repository name
        type: Repository type (default: '')
        bucket: Bucket name (default: '')
        base_path: Base path (default: '')
        client: Client name (default: 'default')
    """

    name: str
    type: str = ''
    bucket: str = ''
    base_path: str = ''
    client: str = 'default'

    def body(self) -> dict:
        """Return the snapshot repository body."""
        return {
            'type': self.type,
            'settings': {
                'bucket': self.bucket,
                'base_path': self.base_path,
                'client': self.client,
            },
        }


class OpenSearchSnapshotError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchSnapshotSpec(Spec):
    """Configuration fields for the Snapshot OpenSearch task."""

    service_name: str = 'os-pos'
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
    def run(self) -> Task:
        opensearch = OpenSearchInstanceManager(self.spec.service_name).client()
        snapshot_repo = SnapshotRepository(
            name=self.spec.snapshot_repository_name,
            type='gcs',
            bucket=self.spec.snapshot_bucket,
            base_path=self.spec.snapshot_base_path,
        )
        logger.debug(f'Creating snapshot repository: {snapshot_repo}')
        snapshot_client = opensearch.snapshot
        snapshot_client.create_repository(repository=snapshot_repo.name, body=snapshot_repo.body())
        logger.debug(f'Creating snapshot: {self.spec.snapshot_name} for indices: {self.spec.indices}')
        snapshot_client.create(
            repository=self.spec.snapshot_repository_name,
            snapshot=self.spec.snapshot_name,
            body={
                'indices': self.spec.indices,
                'ignore_unavailable': True,
                'include_global_state': False,
            },
            cluster_manager_timeout='2h',
            wait_for_completion=True,
        )
        return self
