# Data prep task

from typing import Self

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.parquet2json.converter import convert
from pos.parquet2json.utils import setup_logger


class DataPrepError(OtterError):
    """Base class for exceptions in this module."""


class DataPrepSpec(Spec):
    """Configuration fields for the data prep task.

    This task has the following custom configuration fields:
        - source (str): The path or URL of the parquet file.
        - destination (str): The path or URL of the json file.
    """

    source: str
    destination: str


class DataPrep(Task):
    def __init__(self, spec: DataPrepSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: DataPrepSpec

    @report
    def run(self) -> Task:
        logger.debug(f'converting {self.spec.source} to {self.spec.destination}')
        convert(
            parquet_path=self.spec.source,
            json_path=self.spec.destination,
            log=setup_logger('ERROR'),
            hive_partitioning=False,
        )
        return self
