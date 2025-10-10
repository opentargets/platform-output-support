# Clickhouse backup task
from urllib.parse import urljoin

from clickhouse_connect.driver.exceptions import DatabaseError
from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.clickhouse import (
    ClickhouseBackupQueryParameters,
    ClickhouseInstanceManager,
    backup_table,
    export_to_s3,
    get_table_engine,
    make_backup_urls,
)


class ClickhouseBackupError(OtterError):
    """Base class for exceptions in this module."""


class ClickhouseBackupSpec(Spec):
    """Configuration fields for the backup Clickhouse task."""

    service_name: str = 'ch-pos'
    clickhouse_database: str = 'ot'
    table: str
    gcs_base_path: str


class ClickhouseBackup(Task):
    def __init__(self, spec: ClickhouseBackupSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ClickhouseBackupSpec
        self.backup_urls = make_backup_urls(
            self.spec.gcs_base_path,
            self.spec.clickhouse_database,
            self.spec.table,
        )

    @report
    def run(self) -> Task:
        logger.debug('Backing up ClickHouse')
        client = ClickhouseInstanceManager(name=self.spec.service_name, database=self.spec.clickhouse_database).client()
        if not client:
            raise ClickhouseBackupError(f'Clickhouse service {self.spec.service_name} failed to start')
        parameters = ClickhouseBackupQueryParameters(
            database=self.spec.clickhouse_database,
            table=self.spec.table,
            backup_path=self.backup_urls.backup_url,
            export_path=self.backup_urls.export_url,
        )
        try:
            backup_table(client, parameters)
            table_engine = get_table_engine(client, self.spec.clickhouse_database, self.spec.table)
            if table_engine == 'EmbeddedRocksDB':
                # insert into s3 table because BACKUP does not support this engine
                export_to_s3(client, parameters)
        except DatabaseError as db_err:
            raise ClickhouseBackupError(f'Clickhouse backup failed: {db_err}') from db_err
        return self
