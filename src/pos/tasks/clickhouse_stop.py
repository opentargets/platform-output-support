# Clickhouse stop task
from typing import Self

from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.clickhouse import ClickhouseInstanceManager


class ClickhouseStopError(OtterError):
    """Base class for exceptions in this module."""


class ClickhouseStopSpec(Spec):
    """Configuration fields for the Stop Clickhouse task."""

    service_name: str = 'ch-pos'


class ClickhouseStop(Task):
    def __init__(self, spec: ClickhouseStopSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ClickhouseStopSpec

    @report
    def run(self) -> Self:
        clickhouse = ClickhouseInstanceManager(name=self.spec.service_name)
        clickhouse.stop()
        return self
