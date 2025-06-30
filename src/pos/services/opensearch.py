"""OpenSearch service module."""

from pathlib import Path

from docker.types import Ulimit
from loguru import logger
from opensearchpy import OpenSearch

from pos.services.containerized_service import ContainerizedService, ContainerizedServiceError, reset_timeout


class OpenSearchInstanceManagerError(Exception):
    """Base class for exceptions in this module."""


class OpenSearchInstanceManager(ContainerizedService):
    """OpenSearch instance manager.

    Args:
        name: Container name
        dockerfile: Path to Dockerfile (default: 'config/opensearch/Dockerfile')
        opensearch_version: OpenSearch version (default: '2.19.0')
        init_timeout: Initialization timeout in seconds (default: 30)

    Raises:
        OpenSearchInstanceManagerError: If OpenSearch instance manager fails to start
    """

    def __init__(
        self,
        name: str,
        dockerfile: Path = Path('config/opensearch/Dockerfile'),
        opensearch_version: str = '2.19.0',
        init_timeout: int = 30,
    ) -> None:
        super().__init__(name, dockerfile, opensearch_version, init_timeout)
        self.name = name

    def start(
        self,
        volume_data: str,
        volume_logs: str,
        opensearch_java_opts: str = '-Xms2g -Xmx4g',
    ) -> None:
        """Start OpenSearch instance.

        Args:
            volume_data: Data volume
            volume_logs: Logs volume
            opensearch_java_opts: Java options (default: '-Xms2g -Xmx4g')

        Raises:
            OpenSearchInstanceManagerError: If OpenSearch failed to start
        """
        ports = {'9200': 9200, '9300': 9300}
        environment: dict[str, str] | list[str] | None = {
            'path.data': '/usr/share/opensearch/data',
            'path.logs': '/usr/share/opensearch/logs',
            'network.host': '0.0.0.0',  # noqa: S104
            'discovery.type': 'single-node',
            'discovery.seed_hosts': '[]',
            'bootstrap.memory_lock': 'true',
            'search.max_open_scroll_context': '5000',
            'DISABLE_SECURITY_PLUGIN': 'true',
            'OPENSEARCH_JAVA_OPTS': opensearch_java_opts,
            'thread_pool.write.queue_size': '-1',
        }
        volumes = {
            volume_data: {'bind': '/usr/share/opensearch/data', 'mode': 'rw'},
            volume_logs: {'bind': '/usr/share/opensearch/logs', 'mode': 'rw'},
        }
        ulimits = [
            Ulimit(name='memlock', soft=-1, hard=-1),
            Ulimit(name='nofile', soft=65536, hard=65536),
        ]
        try:
            self._run_container(
                ports=ports,  # type: ignore[reportArgumentType]
                env=environment,
                volumes=volumes,
                ulimits=ulimits,
            )
        except ContainerizedServiceError:
            raise OpenSearchInstanceManagerError('opensearch instance failed to start')

    def client(self) -> OpenSearch:
        return OpenSearch([{'host': 'localhost', 'port': 9200}], use_ssl=False, timeout=3600)

    @reset_timeout
    def is_healthy(self) -> bool:
        """Health check for OpenSearch.

        Args:
            timeout: Timeout in seconds (default: {10})

        Returns:
            bool: True if OpenSearch is healthy, False otherwise
        """
        logger.debug('waiting for opensearch container to become healthy')
        healthy = False
        while self._init_timeout > 0:
            if self.client().ping():
                self.client().cluster.health(wait_for_status='green', cluster_manager_timeout=f'{self._init_timeout}s')  # type: ignore[reportCallIssue]
                healthy = True
                logger.debug('opensearch is healthy')
                break
            self._wait(1)
        return healthy
