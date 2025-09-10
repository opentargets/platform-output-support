# Sync bucket

from pathlib import Path
from typing import Self

from loguru import logger
from otter.manifest.model import Artifact
from otter.storage import get_remote_storage
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report


class UploadError(Exception):
    """Base class for exceptions in this module."""


class UploadSpec(Spec):
    """Configuration fields for the upload task.

    This task has the following custom configuration fields:
        - source (Path): the path, relative to `work_path` to upload.
        - destination (str): The path, relative to `release_uri` to upload to.
    """

    source: Path
    destination: str


class Upload(Task):
    def __init__(self, spec: UploadSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: UploadSpec
        self.context: TaskContext
        self.source = self.context.config.work_path.joinpath(self.spec.source)
        self.destination = f'{context.config.release_uri}/{self.spec.destination}'
        logger.debug(f'Uploading {self.source} to {self.destination}')

    @report
    def run(self) -> Task:
        logger.debug(f'Uploading {self.source} to {self.destination}')
        remote_storage = get_remote_storage(self.destination)
        remote_storage.upload(self.source, self.destination)
        self.artifacts = [Artifact(source=str(self.source), destination=self.destination)]
        logger.debug('Upload successful')
        return self
