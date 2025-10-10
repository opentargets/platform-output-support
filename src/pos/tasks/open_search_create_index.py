# Data prep task

from pathlib import Path

from loguru import logger
from opensearchpy import RequestError
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.services.opensearch import OpenSearchInstanceManager
from pos.utils import get_config


class OpenSearchCreateIndexError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchCreateIndexSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str = 'os-pos'
    dataset: str
    prefix: str


class OpenSearchCreateIndex(Task):
    def __init__(self, spec: OpenSearchCreateIndexSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchCreateIndexSpec
        try:
            self._config = get_config('config/datasets.yaml').opensearch
            self._index_name = self._get_index_name()
            self._mappings = Path(self._config[self.spec.dataset]['mappings'])
        except AttributeError:
            raise OpenSearchCreateIndexError(f'unable to load config for {self.spec.dataset}')

    @report
    def run(self) -> Task:
        logger.debug(f'creating index {self._index_name}')
        opensearch = OpenSearchInstanceManager(self.spec.service_name).client()
        if not opensearch.indices.exists(index=self._index_name):
            try:
                opensearch.indices.create(
                    index=self._index_name,
                    body=self._mappings.read_text(),
                )
            except RequestError as e:
                logger.debug(f'index: {e} already exists')
            logger.debug(f'created index {self._index_name}')
        logger.debug(f'index {self._index_name} already exists')
        return self

    def _get_index_name(self) -> str:
        return f'{self.spec.prefix}_{self._config[self.spec.dataset]["index"]}'
