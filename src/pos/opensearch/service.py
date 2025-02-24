import os
import re
import time
import docker
from loguru import logger
from polars import Boolean
import requests
from requests.exceptions import HTTPError
from docker.client import DockerClient
from docker.models.containers import Container
from docker.models.images import Image
from docker.types import Ulimit


class OpenSearch:
    def __init__(
        self,
        name: str,
        volume_data: str,
        volume_logs: str,
        volume_creds: str,
        snapshot_name: str,
        snapshot_bucket: str,
        snapshot_base_path: str,
        opensearch_java_opts: str,
    ) -> None:
        self._client: DockerClient = docker.from_env()
        self.name = name
        self.container: Container = None
        self.volume_data = volume_data
        self.volume_logs = volume_logs
        self.volume_creds = volume_creds
        self.snapshot_name = snapshot_name
        self.snapshot_bucket = snapshot_bucket
        self.snapshot_base_path = snapshot_base_path
        self.opensearch_java_opts = opensearch_java_opts

    def start(self) -> None:
        logger.info("Starting OpenSearch")
        image = self._build()
        logger.debug("Starting OpenSearch container")
        self.container = self._client.containers.run(
            image,
            auto_remove=True,
            detach=True,
            name=self.name,
            ports={'9200': 9200, '9300': 9300},
            environment={
                'path.data': '/usr/share/opensearch/data',
                'path.logs': '/usr/share/opensearch/logs',
                'network.host': '0.0.0.0',
                'discovery.type': 'single-node',
                'discovery.seed_hosts': [],
                'bootstrap.memory_lock': 'true',
                'search.max_open_scroll_context': 5000,
                'DISABLE_SECURITY_PLUGIN': 'true',
                'OPENSEARCH_JAVA_OPTS': self.opensearch_java_opts,
                'thread_pool.write.queue_size': -1
                },
            volumes={
                self.volume_data: {
                    'bind': '/usr/share/opensearch/data', 'mode': 'rw'
                    },
                self.volume_logs: {
                    'bind': '/usr/share/opensearch/logs', 'mode': 'rw'
                    },
                self.volume_creds: {
                    'bind': '/usr/share/opensearch/config/gac.json', 'mode': 'ro'
                    }
            },
            ulimits=[
                Ulimit(name='memlock', soft=-1, hard=-1),
                Ulimit(name='nofile', soft=65536, hard=65536)
                ]
            )
        self._update_keystore()
        self._register_snapshot_repository()

    def stop(self):
        self.container.stop()

    def isHealthy(self, timeout: int = 6) -> Boolean:
        logger.debug("Waiting for OpenSearch health")
        url = f"http://localhost:9200/_cluster/health?wait_for_status=green&timeout={timeout}s"
        response = requests.get(url)
        if response.status_code != 200:
            return False
        return True

    def _update_keystore(self):
        logger.debug("Updating keystore")
        self.container.exec_run(
            'bin/opensearch-keystore add-file gcs.client.default.credentials_file /usr/share/opensearch/config/gac.json'
        )
        self.container.restart()

    def _build(self) -> Image:
        logger.debug("Building OpenSearch image")
        image, _ = self._client.images.build(path=os.path.join(os.path.dirname(__file__), '.'), tag='opensearch-pos')
        return image

    def _register_snapshot_repository(self) -> HTTPError | None:
        logger.debug("Registering snapshot repository")
        url = f'http://localhost:9200/_snapshot/{self.snapshot_name}'
        payload = {
            "type": "gcs",
            "settings": {
                "bucket": self.snapshot_bucket,
                "base_path": self.snapshot_base_path,
                "client": "default"
            }
        }
        response = requests.put(url, json=payload)
        response.raise_for_status()
