# Sync bucket

from pathlib import Path
from typing import Self
from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.fs import check_dir

import subprocess

class SyncBucketError(Exception):
    """Base class for exceptions in this module."""

class SyncBucketSpec(Spec):
    """Configuration fields for the sync bucket task.

    This task has the following custom configuration fields:
        - source (str): The path or URL of the parquet file/directory or files.
        - destination (Path): The path, relative to `work_path` to download the
            outputs to.
    """

    source: str
    destination: Path

class SyncBucket(Task):

    def __init__(self, spec: SyncBucketSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: SyncBucketSpec
        self.context: TaskContext

    @report
    def run(self) -> Self:
        destination_folder = self.context.config.work_path.joinpath(self.spec.destination)

        logger.debug(f"checking if {destination_folder} exists. If not, create it.")
        # Checking if the destination folder exists. If not, create it.
        check_dir(destination_folder)

        logger.debug(f"Syncing {self.spec.source} with {self.spec.destination}.")
        rsync_command = ["gsutil", "-m", "rsync", "-r", self.spec.source, destination_folder]
        subprocess.run(rsync_command, check=True)

        return self
