"""OpenSearch service module."""

import os
from dataclasses import dataclass
from pathlib import Path

import docker
import requests
from docker.client import DockerClient
from docker.errors import NotFound
from docker.models.containers import Container
from docker.models.images import Image
from docker.types import Ulimit
from loguru import logger
from opensearchpy import OpenSearch
from requests.adapters import HTTPAdapter, Retry


@dataclass
class SnapshotRepository:
    """Snapshot repository configuration fields.

    Arguments:
        name -- Repository name

    Keyword Arguments:
        type -- Repository type (default: {None})
        bucket -- GCS bucket (default: {None})
        base_path -- Base path in GCS bucket (default: {None})
        client -- GCS client (default: {None})
    """

    name: str
    type: str = None
    bucket: str = None
    base_path: str = None
    client: str = 'default'

    def body(self) -> dict:
        """Return the snapshot repository body."""
        return {
            'type': self.type,
            'settings': {
                'bucket': self.bucket,
                'base_path': self.base_path,
                'client': self.client,
            },
        }


class OpenSearchInstanceManagerError(Exception):
    """Base class for exceptions in this module."""


class OpenSearchInstanceManager:
    """OpenSearch instance manager.

    Arguments:
        name -- Container name

    Keyword Arguments:
        host -- Host (default: {"localhost"})
        port -- Port (default: {9200})

    Attributes:
        name -- service/container name
        client -- OpenSearch client
    """

    def __init__(self, name: str, host: str = 'localhost', port: int = 9200) -> None:
        self.name = name
        self._host = host
        self._port = port
        self.client = OpenSearch([{'host': self._host, 'port': self._port}], use_ssl=False, timeout=3600)
        self._docker_client: DockerClient = docker.from_env()
        self._container: Container = None

    def start(
        self,
        volume_data: str | Path,
        volume_logs: str | Path,
        volume_creds: str | Path,
        opensearch_java_opts: str,
        # snapshot_repository: SnapshotRepository = None,
    ) -> None:
        """Start OpenSearch container.

        Arguments:
            volume_data -- Path to data
            volume_logs -- Path to logs
            volume_creds -- Path to GCP credentials
            opensearch_java_opts -- JVM options

        Keyword Arguments:
            snapshot_repository -- SnapshotRespository (default: {None})

        Raises:
            OpenSearchInstanceManagerError: If OpenSearch fails to start
        """
        # TODO: run as correct user
        logger.info('Starting OpenSearch')
        image = self._build()
        self._container = self._docker_client.containers.run(
            image,
            auto_remove=True,
            detach=True,
            name=self.name,
            ports={'9200': self._port, '9300': 9300},
            environment={
                'path.data': '/usr/share/opensearch/data',
                'path.logs': '/usr/share/opensearch/logs',
                'network.host': '0.0.0.0',
                'discovery.type': 'single-node',
                'discovery.seed_hosts': [],
                'bootstrap.memory_lock': 'true',
                'search.max_open_scroll_context': 5000,
                'DISABLE_SECURITY_PLUGIN': 'true',
                'OPENSEARCH_JAVA_OPTS': opensearch_java_opts,
                'thread_pool.write.queue_size': -1,
            },
            volumes={
                volume_data: {'bind': '/usr/share/opensearch/data', 'mode': 'rw'},
                volume_logs: {'bind': '/usr/share/opensearch/logs', 'mode': 'rw'},
                volume_creds: {
                    'bind': '/usr/share/opensearch/config/gac.json',
                    'mode': 'ro',
                },
            },
            ulimits=[
                Ulimit(name='memlock', soft=-1, hard=-1),
                Ulimit(name='nofile', soft=65536, hard=65536),
            ],
        )
        self._update_keystore()
        if self.is_healthy():
            return
        else:
            raise OpenSearchInstanceManagerError('Could not start OpenSearch. Failed health check')

    def stop(self) -> None:
        """Stop OpenSearch container."""
        try:
            self._container = self._docker_client.containers.get(self.name)
            self._container.stop()
        except NotFound:
            logger.error('Container not found')
            return

    def is_healthy(self, timeout: int = 120, retries: int = 10) -> bool:
        """Health check for OpenSearch.

        Keyword Arguments:
            timeout -- timeout for the wait_for_status call (sec) (default: {120})
            retries -- number of retries (default: {10})

        Returns:
            Boolean -- True if healthy, False otherwise
        """
        logger.debug('Waiting for OpenSearch health')
        prefix = 'http://'
        url = f'{prefix}{self._host}:{self._port}/_cluster/health?wait_for_status=green&timeout={timeout}s'
        session = requests.Session()
        retries = Retry(total=retries, backoff_factor=1, status_forcelist=[56])
        session.mount(prefix, HTTPAdapter(max_retries=retries))
        response = session.get(url)
        return response.status_code == 200

    def _update_keystore(self):
        logger.debug('Updating keystore')
        self._container.exec_run(['bin/opensearch-keystore', 'create'])
        self._container.exec_run([
            'bin/opensearch-keystore',
            'add-file',
            'gcs.client.default.credentials_file',
            '/usr/share/opensearch/config/gac.json',
        ])
        self._container.restart()

    def _build(self) -> Image:
        logger.debug('Building OpenSearch image')
        image, _ = self._docker_client.images.build(
            path=os.path.join(os.path.dirname(__file__), '.'), tag='opensearch-pos'
        )
        return image
