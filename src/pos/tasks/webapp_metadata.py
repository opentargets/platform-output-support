# Webapp Metadata Task

from otter.task.model import Spec, Task, TaskContext
from otter.util.errors import OtterError
from otter.task.task_reporter import report

from loguru import logger

class WebappMetadataError(OtterError):
    """Base class for exceptions in this module."""

class WebappMetadataSpec(Spec):
    """Configuration fields for the Webapp Metadata task.

    This task has the following custom configuration fields:
        - metadata_path (str): The path where the metadata in Croissant format is stored.
        - output (str): The path where metadata file is going to be stored.
    """

    url: str
    output: str

class WebappMetadata(Task):
    def __init__(self, spec: WebappMetadataSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: WebappMetadataSpec

    @report
    def run(self) -> None:
        logger.info("Running Webapp Metadata task")
        # run webapp metadata task with the given parameters
