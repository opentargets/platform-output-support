"""Clickhouse service module."""

from pathlib import Path

import clickhouse_connect
from clickhouse_connect.driver.client import Client
from clickhouse_connect.driver.exceptions import DatabaseError
from docker.types.containers import Ulimit
from loguru import logger

from pos.services.containerized_service import ContainerizedService, ContainerizedServiceError, reset_timeout


class ClickhouseInstanceManagerError(Exception):
    """Base class for exceptions in this module."""


class ClickhouseInstanceManager(ContainerizedService):
    """Clickhouse instance manager.

    Args:
        name: Container name
        dockerfile: Path to Dockerfile (default: 'config/clickhouse/Dockerfile')
        clickhouse_version: Clickhouse version (default: '23.3.1.2823')
        database: Database name (default: 'ot')
        init_timeout: Initialization timeout in seconds (default: 10)


    Raises:
        ClickhouseInstanceManagerError: If Clickhouse instance manager fails to start
    """

    def __init__(
        self,
        name: str,
        dockerfile: Path = Path('config/clickhouse/Dockerfile'),
        clickhouse_version: str = '23.3.1.2823',
        database: str = 'default',
        init_timeout: int = 10,
    ) -> None:
        super().__init__(name, dockerfile, clickhouse_version, init_timeout)
        self.name = name
        self.database = database

    def start(self, volume_data: str, volume_logs: str) -> None:
        """Start Clickhouse instance.

        Args:
            volume_data: Data volume
            volume_logs: Logs volume

        Raises:
            ClickhouseInstanceManagerError: If Clickhouse failed to start
        """
        ports = {'9000': 9000, '8123': 8123, '9363': 9363}
        config_path = str(Path('config/clickhouse/config.d').absolute())
        users_path = str(Path('config/clickhouse/users.d').absolute())

        volumes = {
            volume_data: {'bind': '/var/lib/clickhouse', 'mode': 'rw'},
            volume_logs: {'bind': '/var/log/clickhouse-server', 'mode': 'rw'},
            config_path: {'bind': '/etc/clickhouse-server/config.d', 'mode': 'rw'},
            users_path: {'bind': '/etc/clickhouse-server/users.d', 'mode': 'rw'},
        }
        logger.debug(f'volumes: {volumes}')
        ulimits = [Ulimit(name='nofile', soft=262144, hard=262144)]
        try:
            self._run_container(ports=ports, volumes=volumes, ulimits=ulimits)
        except ContainerizedServiceError:
            raise ClickhouseInstanceManagerError(f'clickhouse instance {self.name} failed to start')

    def client(self, reset_timeout: bool = True) -> Client | None:
        """Get Clickhouse client.

        Args:
            reset_timeout: Reset the timeout (default: True)

        Returns:
            Clickhouse client
        """
        if reset_timeout:
            self.reset_init_timeout()
        client: Client | None = None
        while not client and self._init_timeout > 0:
            if not self.is_running():
                self._wait(1)
                continue
            try:
                client = clickhouse_connect.get_client(database=self.database)
            except DatabaseError:
                self._wait(1)
                if self._init_timeout == 0:
                    raise ClickhouseInstanceManagerError(f'Failed to connect to Clickhouse database {self.database}')
                continue
        return client

    @reset_timeout
    def is_healthy(self) -> bool:
        """Check if Clickhouse instance is healthy.

        Returns:
            True if Clickhouse is healthy, False otherwise
        """
        logger.debug('waiting for clickhouse health')
        healthy = False
        while self._init_timeout > 0:
            if not (c := self.client(False)):
                self._wait(1)
                continue
            logger.debug('clickhouse client is available')
            if not c.ping():
                self._wait(1)
                continue
            logger.debug('clickhouse client ping is successful')
            if c.query('SELECT 1').result_set[0][0] == 1:
                healthy = True
                logger.debug('clickhouse is healthy')
                break
            self._wait(1)
        return healthy
