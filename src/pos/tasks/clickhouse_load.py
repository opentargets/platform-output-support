# Clickhouse load task
from pathlib import Path
from typing import Self

from clickhouse_connect.driver.tools import insert_file
from loguru import logger
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
            self._table_name = self._config[self.spec.dataset]['table']
            self._input_dir = self._config[self.spec.dataset]['input_dir']
            self._post_load_sql = self._config[self.spec.dataset].get('postload_script')
        except AttributeError:
            raise ClickhouseLoadError(f'Unable to load config for {self.spec.dataset}')

    @report
    def run(self) -> Self:
        logger.debug('Loading Clickhouse service')
        clickhouse = ClickhouseInstanceManager(name=self.spec.service_name)
        files = self._get_parquet_path().glob('*.parquet')
        for file in files:
            insert_file(clickhouse.client, self._table_name, str(file), fmt='Parquet')
        sql = Path(self._post_load_sql).read_text()
        clickhouse.client.query(sql)
        return self

    def _get_parquet_path(self) -> Path:
        return Path(f'{self.context.config.work_path}/{self.spec.data_dir_parent}/{self._input_dir}')
