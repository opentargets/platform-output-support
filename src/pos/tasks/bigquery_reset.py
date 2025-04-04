# Big query reset task

from typing import Self

from google.cloud.bigquery.schema import SchemaField
from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.gcp.bigquery import BigQuery


class BigqueryResetError(OtterError):
    """Base class for exceptions in this module."""


class BigqueryResetSpec(Spec):
    """Configuration fields for the BigQuery task."""

    dataset_id: str = 'platform_dev'
    project_id: str = 'open-targets-eu-dev'
    location: str = 'eu'
    release: str


class BigqueryReset(Task):
    RELEASE_META_TABLE = 'ot_release'
    RELEASE_META_TABLE_SCHEMA = SchemaField('release', 'STRING')

    def __init__(self, spec: BigqueryResetSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: BigqueryResetSpec
        self._release_metadata = [{'release': self.spec.release}]

    @report
    def run(self) -> Self:
        bigquery = BigQuery(project=self.spec.project_id, location=self.spec.location, dataset=self.spec.dataset_id)
        bigquery.create_dataset()
        self._load_release_metadata(bigquery)
        if self._is_prod():
            logger.debug('Prod, so making dataset public')
            bigquery.make_dataset_access_public()
        return self

    def _load_release_metadata(self, bigquery: BigQuery) -> None:
        bigquery.create_table(self.RELEASE_META_TABLE)
        bigquery.load_from_json(
            self._release_metadata, self.RELEASE_META_TABLE, schema=[self.RELEASE_META_TABLE_SCHEMA]
        )

    def _is_prod(self) -> bool:
        return self.spec.project_id == self.context.scratchpad.sentinel_dict.get('bq_prod_project_id')
