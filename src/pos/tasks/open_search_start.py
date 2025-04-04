# Data prep task
from typing import Self

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearchInstanceManager


class OpenSearchStartError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchStartSpec(Spec):
    """Configuration fields for the start OpenSearch task."""

    service_name: str = 'os-pos'
    host: str = 'localhost'
    port: str = '9200'
    volume_data: str
    volume_logs: str
    volume_creds: str
    opensearch_java_opts: str


class OpenSearchStart(Task):
    def __init__(self, spec: OpenSearchStartSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchStartSpec

    @report
    def run(self) -> Self:
        logger.debug(f'Starting OpenSearch instance {self.spec.service_name}')
        opensearch = OpenSearchInstanceManager(self.spec.service_name, self.spec.host, self.spec.port)
        opensearch.start(
            self.spec.volume_data,
            self.spec.volume_logs,
            self.spec.volume_creds,
            self.spec.opensearch_java_opts,
        )
        return self
