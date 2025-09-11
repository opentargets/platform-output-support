# Data prep task
from typing import Self

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.opensearch import OpenSearchInstanceManager


class OpenSearchStartError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchStartSpec(Spec):
    """Configuration fields for the start OpenSearch task."""

    service_name: str = 'os-pos'
    volume_data: str
    volume_logs: str
    opensearch_version: str = '2.19.0'
    opensearch_java_opts: str
    startup_wait: str = '60'


class OpenSearchStart(Task):
    def __init__(self, spec: OpenSearchStartSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchStartSpec

    @report
    def run(self) -> Task:
        logger.debug(f'starting opensearch instance {self.spec.service_name}')
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            opensearch_version=self.spec.opensearch_version,
            init_timeout=int(self.spec.startup_wait),
        )

        opensearch.start(
            self.spec.volume_data,
            self.spec.volume_logs,
            self.spec.opensearch_java_opts,
        )
        return self
