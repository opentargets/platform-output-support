# Big query load task

from pathlib import Path
from typing import Self

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.gcp.bigquery import BigQuery
from pos.utils import get_config


class BigqueryLoadError(OtterError):
    """Base class for exceptions in this module."""


class BigqueryLoadSpec(Spec):
    """Configuration fields for the BigQuery task."""

    dataset_id: str = 'platform_dev'
    project_id: str = 'open-targets-eu-dev'
    location: str = 'eu'
    table: str
    base_uri: str
    file_pattern: str = '*.parquet'
    format: str = 'PARQUET'


class BigqueryLoad(Task):
    def __init__(self, spec: BigqueryLoadSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: BigqueryLoadSpec
        try:
            self._config = get_config('config/datasets.yaml').bigquery
            self._table_name = self._config[self.spec.table].index
            self._input_dir = self._config[self.spec.table].input_dir
            self._path = f'{self.spec.base_uri}/{self._input_dir}/{self.spec.file_pattern}'
            self._hive_partition = bool(self._config[self.spec.table].get('hive_partition'))
        except AttributeError:
            raise BigqueryLoadError(f'unable to load config for {self.spec.table}')

    @report
    def run(self) -> Self:
        bigquery = BigQuery(project=self.spec.project_id, location=self.spec.location, dataset=self.spec.dataset_id)
        if self._hive_partition:
            logger.debug(f'loading {self._path} into {self._table_name} with hive partition')
            hive_partition_source = Path(f'{self.spec.base_uri}/{self._input_dir}').parent
            bigquery.load_from_uri(
                self._path,
                self._table_name,
                self.spec.format,
                hive_partition_source=hive_partition_source,
            )
        else:
            bigquery.load_from_uri(self._path, self._table_name, self.spec.format)
        return self
