# Data prep task

from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.parquet2json.converter import convert
from pos.parquet2json.utils import setup_logger
from pos.utils import get_config


class DataPrepError(OtterError):
    """Base class for exceptions in this module."""


class DataPrepSpec(Spec):
    """Configuration fields for the data prep task.

    This task has the following custom configuration fields:
        - parquet_parent (str): The path or URL of the parquet parent directory.
        i.e. here /path/to/parquet/<dataset>/1.parquet it would be /path/to/parquet
        - json_parent (str): The path or URL of the json parent directory.
        i.e. here /path/to/json/<dataset>/1.json it would be /path/to/json
    """

    parquet_parent: str
    json_parent: str
    dataset: str


class DataPrep(Task):
    def __init__(self, spec: DataPrepSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: DataPrepSpec
        self._config = get_config("config/datasets.yaml").opensearch
        self._input_dir = self._config[self.spec.dataset].input_dir
        self._output_dir = self._config[self.spec.dataset].output_dir

    @report
    def run(self) -> None:
        convert(
            parquet_path=self._get_parquet_source(self.spec.parquet_parent),
            json_path=self._get_json_destination(self.spec.json_parent),
            log=setup_logger("ERROR"),
            hive_partitioning=False,
        )

    def _get_parquet_source(self, parquet_parent: str) -> str:
        return f"{parquet_parent}/{self._input_dir}/*.parquet"

    def _get_json_destination(self, json_parent: str) -> str:
        return f"{json_parent}/{self._output_dir}/{self.spec.dataset}.json"
