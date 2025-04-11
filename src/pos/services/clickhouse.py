"""Clickhouse service module."""

import clickhouse_connect
from clickhouse_connect.driver import Client
from clickhouse_connect.driver.exceptions import DatabaseError
from docker.types.containers import Ulimit
from loguru import logger

from pos.services.containerized_service import ContainerizedService, ContainerizedServiceError, reset_timeout
from pos.utils import absolute_path


class ClickhouseInstanceManagerError(Exception):
    """Base class for exceptions in this module."""


class ClickhouseInstanceManager(ContainerizedService):
    """Clickhouse instance manager.

    Args:
        name: Container name
        image: Image name/Dockerfile, can be a string, '<image>:<tag>' or a Path to a Dockerfile
        database: Database name (default: 'ot')
        init_timeout: Initialization timeout in seconds (default: 10)

    Attributes:
        name: Container name
        image: Image name
        database: Database name
        init_timeout: Initialization timeout in seconds
        container: Container object
        image: Image object

    """

    def __init__(
        self,
        name: str,
        image: str = 'clickhouse/clickhouse-server:23.3.1.2823',
        database: str = 'ot',
        init_timeout: int = 10,
    ) -> None:
        super().__init__(name, image, init_timeout)
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
        ports = {'9000': 9000, '8123': 8123}
        volumes = {
            volume_data: {'bind': '/var/lib/clickhouse', 'mode': 'rw'},
            volume_logs: {'bind': '/var/log/clickhouse-server', 'mode': 'rw'},
            absolute_path('config/clickhouse/config.d'): {'bind': '/etc/clickhouse-server/config.d', 'mode': 'rw'},
            absolute_path('config/clickhouse/users.d'): {'bind': '/etc/clickhouse-server/users.d', 'mode': 'rw'},
            absolute_path('config/clickhouse/schema'): {'bind': '/docker-entrypoint-initdb.d', 'mode': 'rw'},
        }
        logger.debug(f'volumes: {volumes}')
        ulimits = [Ulimit(name='nofile', soft=262144, hard=262144)]
        try:
            self._run_container(ports=ports, volumes=volumes, ulimits=ulimits)
        except ContainerizedServiceError:
            raise ClickhouseInstanceManagerError(f'Clickhouse instance {self.name} failed to start.')

    def client(self, reset_timeout: bool = True) -> Client | None:
        """Get Clickhouse client.

        Args:
            reset_timeout: Reset the timeout (default: {True})

        Returns:
            Clickhouse client
        """
        if reset_timeout:
            self.reset_init_timeout()
        client = None
        while not client and self._init_timeout > 0:
            if not self.is_running():
                self._wait(1)
                continue
            try:
                client = clickhouse_connect.get_client(database=self.database)
            except DatabaseError:
                self._wait(1)
                if self._init_timeout == 0:
                    logger.error(f'Clickhouse client connection to {self.database} failed')
                    raise ClickhouseInstanceManagerError(f'Failed to connect to Clickhouse database {self.database}')
                continue
        return client

    @reset_timeout
    def is_healthy(self) -> bool:
        """Check if Clickhouse instance is healthy.

        Returns:
            True if Clickhouse is healthy, False otherwise
        """
        logger.debug('Waiting for Clickhouse health')
        healthy = False
        while self._init_timeout > 0:
            if not self.client(False):
                self._wait(1)
                continue
            logger.debug('Clickhouse client is available')
            if not self.client(False).ping():
                self._wait(1)
                continue
            logger.debug('Clickhouse client ping is successful')
            response = self.client(False).query('SELECT 1')
            if response.result_set[0][0] == 1:
                healthy = True
                logger.debug('Clickhouse is healthy')
                break
            self._wait(1)
        return healthy
