# Clickhouse load task
from typing import Self

from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.clickhouse.service import ClickhouseInstanceManager
from pos.utils import get_config


class ClickhouseLoadError(OtterError):
    """Base class for exceptions in this module."""


class ClickhouseLoadSpec(Spec):
    """Configuration fields for the Load Clickhouse task."""

    service_name: str = 'ch-pos'
    dataset: str
    data_dir_parent: str


class ClickhouseLoad(Task):
    def __init__(self, spec: ClickhouseLoadSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ClickhouseLoadSpec
        try:
            self._config = get_config('config/datasets.yaml').clickhouse
        except AttributeError:
            raise ClickhouseLoadError(f'Unable to load config for {self.spec.dataset}')

    @report
    def run(self) -> Self:
        clickhouse = ClickhouseInstanceManager(name=self.spec.service_name)
        # glob files
        # for file in glob_files:
        # insert_file(clickhouse.client, <table>, <file_path>)
        return self
