# Clickhouse backup task
from dataclasses import dataclass
from os import getenv
from string import Template
from urllib.parse import urljoin

from clickhouse_connect.driver.client import Client
from clickhouse_connect.driver.exceptions import DatabaseError
from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.clickhouse import ClickhouseInstanceManager


class ClickhouseBackupError(OtterError):
    """Base class for exceptions in this module."""


class ClickhouseBackupSpec(Spec):
    """Configuration fields for the backup Clickhouse task."""

    service_name: str = 'ch-pos'
    clickhouse_database: str = 'ot'
    table: str
    gcs_base_path: str


@dataclass
class ClickhouseBackupQueryParameters:
    database: str
    table: str
    backup_path: str
    export_path: str
    access_key_id: str
    secret_access_key: str

    def asdict(self) -> dict[str, str]:
        return {
            'database': self.database,
            'table': self.table,
            'backup_path': self.backup_path,
            'export_path': self.export_path,
            'access_key_id': self.access_key_id,
            'secret_access_key': self.secret_access_key,
        }


class ClickhouseBackup(Task):
    def __init__(self, spec: ClickhouseBackupSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ClickhouseBackupSpec
        self.backup_url = urljoin(
            self.spec.gcs_base_path,
            '/'.join([
                self.context.scratchpad.sentinel_dict.get('product'),
                str(self.context.scratchpad.sentinel_dict.get('release')),
                self.spec.table,
            ]),
        )
        self.export_url = urljoin(self.backup_url, 'export.zstd')
        logger.debug(f'backup_url: {self.backup_url}')
        logger.debug(f'export_url: {self.export_url}')

    @report
    def run(self) -> Task:
        logger.debug('Backing up ClickHouse')
        client = ClickhouseInstanceManager(name=self.spec.service_name, database=self.spec.clickhouse_database).client()
        if not client:
            raise ClickhouseBackupError(f'Clickhouse service {self.spec.service_name} failed to start')
        access_key_id = getenv('GCS_ACCESS_KEY_ID')
        secret_access_key = getenv('GCS_SECRET_ACCESS_KEY')
        if not access_key_id or not secret_access_key:
            logger.error('GCS credentials not set in environment variables')
            raise ClickhouseBackupError('GCS credentials not set in environment variables')
        parameters = ClickhouseBackupQueryParameters(
            database=self.spec.clickhouse_database,
            table=self.spec.table,
            backup_path=self.backup_url,
            export_path=self.export_url,
            access_key_id=access_key_id,
            secret_access_key=secret_access_key,
        ).asdict()
        self.backup_table_query(client, parameters)
        table_engine = self._get_table_engine(client, self.spec.clickhouse_database, self.spec.table)
        if table_engine == 'EmbeddedRocksDB':
            # insert into s3 table because BACKUP does not support this engine
            self.export_to_s3_query(client, parameters)
        return self

    def backup_table_query(self, client: Client, parameters: dict) -> None:
        """Backup ClickHouse table to S3 compatible storage (GCS).

        Args:
            client (Client): ClickHouse client instance.
            parameters (dict): Dictionary containing query parameters.

        Raises:
            ClickhouseBackupError: If the backup operation fails
            e.g. if the backup path already exists.
        """
        query = Template(
            """BACKUP TABLE `${database}`.`${table}` \
        TO S3('${backup_path}', \
        '${access_key_id}', \
        '${secret_access_key}')"""
        ).substitute(parameters)
        try:
            client.query(query=query)
        except DatabaseError as db_err:
            raise ClickhouseBackupError(f'Clickhouse backup to S3 failed: {db_err}') from db_err

    def export_to_s3_query(self, client: Client, parameters: dict) -> None:
        """Export ClickHouse table to S3 compatible storage (GCS).

        This is used for tables with the EmbeddedRocksDB engine which
        is not supported by the BACKUP command.

        Args:
            client (Client): ClickHouse client instance.
            parameters (dict): Dictionary containing query parameters.

        Raises:
            ClickhouseBackupError: If the export operation fails.
        """
        query = Template(
            """INSERT INTO FUNCTION s3(\
        '${export_path}', \
        '${access_key_id}', \
        '${secret_access_key}',
        Native) \
        SELECT * FROM `${database}`.`${table}`"""
        ).substitute(parameters)
        try:
            client.query(query)
        except DatabaseError as db_err:
            raise ClickhouseBackupError(f'Clickhouse export to S3 failed: {db_err}') from db_err

    def _get_table_engine(self, client: Client, database: str, table: str) -> str | None:
        """Get the engine type of a ClickHouse table.

        Args:
            client (Client): ClickHouse client instance.
            database (str): Name of the database.
            table (str): Name of the table.

        Returns:
            str | None: The engine type of the table, or None if not found.
        """
        query = Template(
            """SELECT engine \
        FROM system.tables \
        WHERE database='${database}' AND name='${table}'"""
        ).substitute({'database': database, 'table': table})
        table_engine_query = client.query(query=query).first_row
        return table_engine_query[0] if table_engine_query else None
