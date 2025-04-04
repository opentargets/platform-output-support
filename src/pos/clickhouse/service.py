"""Clickhouse service module."""

from pathlib import Path

import clickhouse_connect
import docker
from docker.client import DockerClient
from docker.errors import APIError, ImageNotFound, NotFound
from docker.models.containers import Container
from docker.models.images import Image
from docker.types.containers import Ulimit
from loguru import logger

from pos.utils import absolute_path


class ClickhouseInstanceManagerError(Exception):
    """Base class for exceptions in this module."""


class ClickhouseInstanceManager:
    """Clickhouse instance manager."""

    CONFIG_PATH = absolute_path('config/clickhouse/config.d')
    USERS_PATH = absolute_path('config/clickhouse/users.d')
    SCHEMA_PATH = absolute_path('config/clickhouse/schema')
    # SCRIPTS_PATH = absolute_path('config/clickhouse/scripts')

    def __init__(
        self, name: str, image: str = 'clickhouse/clickhouse-server', version: str = '23.3.1.2823', database: str = 'ot'
    ) -> None:
        self.name = name
        self._docker_client: DockerClient = docker.from_env()
        self._image: Image = self._get_image(f'{image}:{version}')
        self.client = clickhouse_connect.get_client(database=database)
        self._container: Container = Container()

    def start(self, volume_data: str, volume_logs: str) -> None:
        """Start Clickhouse instance.

        Arguments:
            volume_data -- Data volume
            volume_logs -- Logs volume
        """
        Path(volume_data).mkdir(parents=True, exist_ok=True)
        Path(volume_logs).mkdir(parents=True, exist_ok=True)
        self._container = self._docker_client.containers.run(
            self._image,
            name=self.name,
            auto_remove=True,
            detach=True,
            ports={'9000': 9000, '8123': 8123},
            volumes={
                volume_data: {'bind': '/var/lib/clickhouse', 'mode': 'rw'},
                volume_logs: {'bind': '/var/log/clickhouse-server', 'mode': 'rw'},
                self.CONFIG_PATH: {'bind': '/etc/clickhouse-server/config.d', 'mode': 'rw'},
                self.USERS_PATH: {'bind': '/etc/clickhouse-server/users.d', 'mode': 'rw'},
                self.SCHEMA_PATH: {'bind': '/docker-entrypoint-initdb.d', 'mode': 'rw'},
                self.SCRIPTS_PATH: {'bind': '/scripts', 'mode': 'rw'},
            },
            ulimits=[Ulimit(name='nofile', soft=262144, hard=262144)],
        )

    def stop(self) -> None:
        """Stop Clickhouse instance."""
        try:
            self._container = self._docker_client.containers.get(self.name)
            self._container.stop()
        except NotFound:
            logger.error('Container not found')
            raise ClickhouseInstanceManagerError(f'Container {self.name} not found')

    def _get_image(self, name: str) -> Image:
        try:
            return self._docker_client.images.get(name)
        except (ImageNotFound, APIError):
            raise ClickhouseInstanceManagerError(f'Image {name} not found')
