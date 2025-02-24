# Data prep task

from typing import Self

from otter.scratchpad import Scratchpad
from otter.storage import get_remote_storage
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.tasks.data_prep import DataPrepSpec
from pos.utils import get_config


class ExplodeDatasetsError(OtterError):
    """Base class for exceptions in this module."""


class ExplodeDatasetsSpec(Spec):
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


class ExplodeDatasets(Task):
    def __init__(self, spec: ExplodeDatasetsSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: ExplodeDatasetsSpec
        self.scratchpad = Scratchpad({})
        try:
            self._config = get_config('config/datasets.yaml').opensearch
            self._input_dir = self._config[self.spec.dataset].input_dir
            self._output_dir = self._config[self.spec.dataset].output_dir
        except AttributeError:
            raise ExplodeDatasetsError(f'Unable to load config for {self.spec.dataset}')

    @report
    def run(self) -> Self:
        glob = self._get_parquet_source(self.spec.parquet_parent)
        remote_storage = get_remote_storage(glob)
        files = remote_storage.glob(glob)
        for file in files:
            spec = DataPrepSpec(
                name=f'data_prep {file}',
                source=file,
                destination=self._get_json_destination(self.spec.json_parent),
            )
            self.scratchpad.store('each', file)
            self.context.specs.append(Spec.model_validate(self.scratchpad.replace_dict(spec.model_dump())))
        return self

    def _get_parquet_source(self, parquet_parent: str) -> str:
        return f'{parquet_parent}/{self._input_dir}/*.parquet'

    def _get_json_destination(self, json_parent: str) -> str:
        return f'{json_parent}/{self._output_dir}/{self.spec.dataset}.json'
