# Clickhouse restore task
from urllib.parse import urljoin

import clickhouse_connect
from clickhouse_connect.driver.exceptions import DatabaseError
from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.clickhouse import (
    ClickhouseBackupQueryParameters,
    create_database,
    get_table_engine,
    import_from_s3,
    restore_table,
)


class ClickhouseRestoreError(OtterError):
    """Base class for exceptions in this module."""


class ClickhouseRestoreSpec(Spec):
    """Configuration fields for the restore Clickhouse task."""

    host: str = 'localhost'
    port: str = '9000'
    clickhouse_database: str = 'ot'
    table: str
    gcs_base_path: str


class ClickhouseRestore(Task):
    def __init__(self, spec: ClickhouseRestoreSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ClickhouseRestoreSpec
        self.backup_url = urljoin(
            self.spec.gcs_base_path,
            '/'.join([
                self.context.scratchpad.sentinel_dict.get('product'),
                str(self.context.scratchpad.sentinel_dict.get('release')),
                self.spec.table,
            ])
            + '/',
        )
        self.export_url = urljoin(self.restore_url, 'export.parquet.lz4')

    @report
    def run(self) -> Task:
        logger.debug('Restore ClickHouse')
        try:
            client = clickhouse_connect.get_client(
                host=self.spec.host, port=self.spec.port, database=self.spec.clickhouse_database
            )
        except DatabaseError as db_err:
            raise ClickhouseRestoreError(f'Clickhouse client connection failed: {db_err}') from db_err
        parameters = ClickhouseBackupQueryParameters(
            database=self.spec.clickhouse_database,
            table=self.spec.table,
            backup_path=self.backup_url,
            export_path=self.export_url,
        )
        try:
            create_database(client, self.spec.clickhouse_database)
            restore_table(client, parameters)
            table_engine = get_table_engine(client, self.spec.clickhouse_database, self.spec.table)
            if table_engine == 'EmbeddedRocksDB':
                # insert into s3 table because BACKUP/RESTORE does not support this engine
                import_from_s3(client, parameters)
        except DatabaseError as db_err:
            raise ClickhouseRestoreError(f'Clickhouse restore from S3 failed: {db_err}') from db_err
        return self
