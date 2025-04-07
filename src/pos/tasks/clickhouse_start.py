# Clickhouse start task
from typing import Self

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.clickhouse.service import ClickhouseInstanceManager


class ClickhouseStartError(OtterError):
    """Base class for exceptions in this module."""


class ClickhouseStartSpec(Spec):
    """Configuration fields for the start Clickhouse task."""

    service_name: str = 'ch-pos'
    volume_data: str
    volume_logs: str


class ClickhouseStart(Task):
    def __init__(self, spec: ClickhouseStartSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ClickhouseStartSpec

    @report
    def run(self) -> Self:
        logger.debug('Starting Clickhouse service')
        clickhouse = ClickhouseInstanceManager(name=self.spec.service_name)
        clickhouse.start(self.spec.volume_data, self.spec.volume_logs)
        return self
