# Data prep task


from loguru import logger
from opensearchpy import OpenSearch
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.opensearch import SnapshotRepository


class OpensearchRestoreError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchRestoreSpec(Spec):
    """Configuration fields for the restore from snapshot OpenSearch task."""

    snapshot_repository_name: str
    snapshot_name: str
    snapshot_bucket: str
    snapshot_base_path: str
    indices: str = '*,-.*'
    host: str = 'localhost'
    port: str = '9200'


class OpenSearchRestore(Task):
    def __init__(self, spec: OpenSearchRestoreSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchRestoreSpec

    @report
    def run(self) -> Task:
        opensearch = OpenSearch([{'host': self.spec.host, 'port': self.spec.port}], use_ssl=False, timeout=7200)
        snapshot_repo = SnapshotRepository(
            name=self.spec.snapshot_repository_name,
            type='gcs',
            bucket=self.spec.snapshot_bucket,
            base_path=self.spec.snapshot_base_path,
        )
        logger.debug(f'Registering snapshot repository: {snapshot_repo}')
        snapshot_client = opensearch.snapshot
        snapshot_client.create_repository(repository=snapshot_repo.name, body=snapshot_repo.body())
        logger.debug(f'Restore from snapshot: {self.spec.snapshot_name} for indices: {self.spec.indices}')
        snapshot_client.restore(
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
