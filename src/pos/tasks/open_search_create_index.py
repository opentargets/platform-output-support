# Data prep task

from pathlib import Path
from typing import Self

from loguru import logger
from opensearchpy import RequestError
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearchInstanceManager
from pos.utils import get_config


class OpenSearchCreateIndexError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchCreateIndexSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str = 'os-pos'
    host: str = 'localhost'
    port: str = '9200'
    dataset: str


class OpenSearchCreateIndex(Task):
    def __init__(self, spec: OpenSearchCreateIndexSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchCreateIndexSpec
        try:
            self._config = get_config('config/datasets.yaml').opensearch
            self._index_name = self._config[self.spec.dataset]['index']
            self._mappings = Path(self._config[self.spec.dataset]['mappings'])
        except AttributeError:
            raise OpenSearchCreateIndexError(f'Unable to load config for {self.spec.dataset}')

    @report
    def run(self) -> Self:
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        if not opensearch.client.indices.exists(index=self._index_name):
            try:
                opensearch.client.indices.create(
                    index=self._index_name,
                    body=self._mappings.read_text(),
                )
            except RequestError as e:
                logger.debug(f'Index: {e} already exists')
            logger.debug(f'Created index {self._index_name}')
        logger.debug(f'Index {self._index_name} already exists')
        return self
