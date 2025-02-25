"""OpenSearch service module."""

import json
import os
from pathlib import Path
import time
from dataclasses import dataclass

import docker
import requests
from docker.client import DockerClient
from docker.errors import NotFound
from docker.models.containers import Container
from docker.models.images import Image
from docker.types import Ulimit
from loguru import logger
from polars import Boolean
from requests.exceptions import HTTPError


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
    client: str = "default"


class OpenSearchError(Exception):
    """Base class for exceptions in this module."""


class OpenSearch:
    """OpenSearch service class.

    Arguments:
        name -- Container name
    """

    def __init__(
        self,
        name: str,
    ) -> None:
        self._client: DockerClient = docker.from_env()
        self.name = name
        self.container: Container = None

    def start(
        self,
        volume_data: str | Path,
        volume_logs: str | Path,
        volume_creds: str | Path,
        opensearch_java_opts: str,
        snapshot_repository: SnapshotRepository = None,
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
            OpenSearchError: If OpenSearch fails to start
        """
        logger.info("Starting OpenSearch")
        image = self._build()
        self.container = self._client.containers.run(
            image,
            auto_remove=True,
            detach=True,
            name=self.name,
            ports={"9200": 9200, "9300": 9300},
            environment={
                "path.data": "/usr/share/opensearch/data",
                "path.logs": "/usr/share/opensearch/logs",
                "network.host": "0.0.0.0",
                "discovery.type": "single-node",
                "discovery.seed_hosts": [],
                "bootstrap.memory_lock": "true",
                "search.max_open_scroll_context": 5000,
                "DISABLE_SECURITY_PLUGIN": "true",
                "OPENSEARCH_JAVA_OPTS": opensearch_java_opts,
                "thread_pool.write.queue_size": -1,
            },
            volumes={
                volume_data: {"bind": "/usr/share/opensearch/data", "mode": "rw"},
                volume_logs: {"bind": "/usr/share/opensearch/logs", "mode": "rw"},
                volume_creds: {
                    "bind": "/usr/share/opensearch/config/gac.json",
                    "mode": "ro",
                },
            },
            ulimits=[
                Ulimit(name="memlock", soft=-1, hard=-1),
                Ulimit(name="nofile", soft=65536, hard=65536),
            ],
        )
        self._update_keystore()
        if snapshot_repository:
            if self.is_healthy():
                self._register_snapshot_repository(snapshot_repository)
            else:
                raise OpenSearchError("Could not start OpenSearch. Failed health check")

    def stop(self) -> None:
        """Stop OpenSearch container."""
        try:
            self.container = self._client.containers.get(self.name)
            self.container.stop()
        except NotFound:
            logger.error("Container not found")
            return

    def snapshot(self, snapshot_repo: SnapshotRepository, snapshot_name: str) -> None:
        """Create a snapshot of the OpenSearch data.

        Arguments:
            snapshot_repo -- Snapshot repository configuration
            snapshot_name -- Snapshot name
        """
        logger.debug("Creating snapshot")
        url = f"http://localhost:9200/_snapshot/{snapshot_repo.name}/{snapshot_name}"
        payload = {
            "indices": "-.*",
            "ignore_unavailable": True,
            "include_global_state": False,
        }
        response = requests.put(url, json=payload)
        response.raise_for_status()

    def create_index(self, index: str, mappings: str | Path) -> None:
        """Create an index in OpenSearch.

        Arguments:
            index -- Index name
            mappings -- Path to index mappings
        """
        logger.debug("Creating index")
        url = f"http://localhost:9200/{index}"
        with open(mappings, "r") as f:
            json_mappings = json.load(f)
            response = requests.put(url, json=json_mappings)
            response.raise_for_status()

    def is_healthy(
        self, timeout: int = 6, retries: int = 3, delay: int = 10
    ) -> Boolean:
        """Health check for OpenSearch.

        Keyword Arguments:
            timeout -- timeout for the wait_for_status call (sec) (default: {6})
            retries -- number of retries (default: {3})
            delay -- delay between retries (sec) (default: {10})

        Returns:
            Boolean -- True if healthy, False otherwise
        """
        logger.debug("Waiting for OpenSearch health")
        url = f"http://localhost:9200/_cluster/health?wait_for_status=green&timeout={timeout}s"
        while retries > 0:
            try:
                response = requests.get(url)
                logger.debug(f"Health check response: {response.json()}")
                if response.status_code != 200:
                    return False
                return True
            except requests.exceptions.ConnectionError:
                logger.warning("Connection error, retrying")
                retries -= 1
                time.sleep(delay)
                continue
        return False

    def _update_keystore(self):
        logger.debug("Updating keystore")
        self.container.exec_run(["bin/opensearch-keystore", "create"])
        self.container.exec_run(
            [
                "bin/opensearch-keystore",
                "add-file",
                "gcs.client.default.credentials_file",
                "/usr/share/opensearch/config/gac.json",
            ]
        )
        self.container.restart()

    def _build(self) -> Image:
        logger.debug("Building OpenSearch image")
        image, _ = self._client.images.build(
            path=os.path.join(os.path.dirname(__file__), "."), tag="opensearch-pos"
        )
        return image

    def _register_snapshot_repository(
        self, snap_repo: SnapshotRepository
    ) -> HTTPError | None:
        url = f"http://localhost:9200/_snapshot/{snap_repo.name}"
        payload = {
            "type": snap_repo.type,
            "settings": {
                "bucket": snap_repo.bucket,
                "base_path": snap_repo.base_path,
                "client": snap_repo.client,
            },
        }
        response = requests.put(url, json=payload)
        response.raise_for_status()
