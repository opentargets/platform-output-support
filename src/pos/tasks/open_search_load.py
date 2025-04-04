# Data prep task

import json
from collections.abc import Generator
from pathlib import Path
from typing import Any, Self

from loguru import logger
from opensearchpy import helpers
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.opensearch.service import OpenSearchInstanceManager
from pos.utils import get_config


class OpenSearchLoadError(OtterError):
    """Base class for exceptions in this module."""


class OpenSearchLoadSpec(Spec):
    """Configuration fields for the create index OpenSearch task."""

    service_name: str = 'os-pos'
    host: str = 'localhost'
    port: str = '9200'
    dataset: str
    json_parent: str


class OpenSearchLoad(Task):
    def __init__(self, spec: OpenSearchLoadSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OpenSearchLoadSpec
        try:
            self._config = get_config('config/datasets.yaml').opensearch
            self._index_name = self._config[self.spec.dataset]['index']
            self._id_field = self._config[self.spec.dataset].get('id_field')
            self._output_dir = self._config[self.spec.dataset]['output_dir']
        except AttributeError:
            raise OpenSearchLoadError(f'Unable to load config for {self.spec.dataset}')

    @report
    def run(self) -> Self:
        logger.debug(f'Loading data into index {self._index_name}')
        opensearch = OpenSearchInstanceManager(
            self.spec.service_name,
            self.spec.host,
            self.spec.port,
        )
        json_file = self._get_json_path()
        if not json_file.exists():
            logger.warning(f'No data for {self.spec.dataset} loaded. File {json_file} does not exist')
            return self
        for success, info in helpers.parallel_bulk(
            opensearch.client,
            index=self._index_name,
            actions=self._generate_data(json_file),
            thread_count=4,
            chunk_size=2000,
            queue_size=-1,
        ):
            if not success:
                logger.error(f'Failed to index document: {info}')
        opensearch.client.indices.refresh(index=self._index_name)
        return self

    # TODO: add a counter to track the number of records read in
    # then use to validate against the number of records indexed
    def _generate_data(self, json_file: str | Path) -> Generator[dict[str, Any]] | Generator[str]:
        with open(json_file) as rows:
            if self._id_field:
                logger.info(f'Using {self._id_field} as the document id')
                for row in rows:
                    doc = {'_source': row, '_id': json.loads(row)[self._id_field]}
                    yield doc
            else:
                logger.info('No document id field specified')
                for doc in rows:
                    yield doc

    def _get_json_path(self) -> Path:
        return Path(
            f'{self.context.config.work_path}/{self.spec.json_parent}/{self._output_dir}/{self.spec.dataset}.json'
        )
