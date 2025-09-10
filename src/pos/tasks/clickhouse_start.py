# Clickhouse start task
from typing import Self

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.clickhouse import ClickhouseInstanceManager


class ClickhouseStartError(OtterError):
    """Base class for exceptions in this module."""


class ClickhouseStartSpec(Spec):
    """Configuration fields for the start Clickhouse task."""

    service_name: str = 'ch-pos'
    volume_data: str
    volume_logs: str
    clickhouse_version: str = '23.3.1.2823'


class ClickhouseStart(Task):
    def __init__(self, spec: ClickhouseStartSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ClickhouseStartSpec

    @report
    def run(self) -> Task:
        logger.debug('starting Clickhouse service')
        clickhouse = ClickhouseInstanceManager(
            name=self.spec.service_name, clickhouse_version=self.spec.clickhouse_version
        )
        clickhouse.start(self.spec.volume_data, self.spec.volume_logs)
        return self
