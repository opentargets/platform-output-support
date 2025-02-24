# Data prep task

from otter.task.task_reporter import report
from otter.task.model import Spec, Task, TaskContext
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearch


class OpenSearchStartError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchStartSpec(Spec):
    """Configuration fields for the start OpenSearch task.
    """
    service_name: str
    volume_data: str
    volume_logs: str
    volume_creds: str
    snapshot_name: str
    snapshot_bucket: str
    snapshot_base_path: str
    opensearch_java_opts: str


class OpenSearchStart(Task):
    def __init__(self, spec: OpenSearchStartSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchStartSpec

    @report
    def run(self) -> None:
        print("opensearch start run")
        opensearch = OpenSearch(
            self.spec.service_name,
            self.spec.volume_data,
            self.spec.volume_logs,
            self.spec.volume_creds,
            self.spec.snapshot_name,
            self.spec.snapshot_bucket,
            self.spec.snapshot_base_path,
            self.spec.opensearch_java_opts
        )
        opensearch.start()
