# Sync bucket

from pathlib import Path
from typing import Self
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
        - destination (Path): The path, relative to `release_uri` to upload the
            results to.
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
        print(destination_folder)
        print(self.context.config.work_path)
        print(f"add {self.context.config.work_path} with {self.spec.destination}.")
        print(f"Syncing {self.spec.source} with {self.spec.destination}.")
        # Checking if the destination folder exists. If not, create it.
        check_dir(destination_folder)
        rsync_command = ["gsutil", "-m", "rsync", "-r", self.spec.source, destination_folder]
        subprocess.run(rsync_command, check=True)
        print(f"Synced {self.spec.source} with {self.spec.destination}.")

        return self
