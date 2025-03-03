# OT Croissant Task

from pathlib import Path
from typing import Self

from otter.task.model import Spec, Task, TaskContext
from otter.util.errors import OtterError, ScratchpadError
from otter.task.task_reporter import report
from otter.storage import get_remote_storage
from otter.manifest.model import Artifact

import json
from datetime import datetime

from loguru import logger

from ot_croissant.crumbs.metadata import PlatformOutputMetadata


class OtCroissantError(OtterError):
    """Base class for exceptions in this module."""

class OtCroissantSpec(Spec):
    """Configuration fields for the OT Croissant task.

    This task has the following custom configuration fields:
        - ftp_address (str): The URL of the ftp where the data is going to be published.
        - gcp_address (str): The URL of the google bucket where the data is going to be published.
        - dataset_path (Path): The path where the parquet outputs are stored. These outputs are going to be used to extract the schema.
        - date_published (str): The date when the data was published. The date format is YYYY-MM-DD.
        - output (str): Path (relative to `work_path` or `release_uri`) to store the metadata at.
    """

    ftp_address: str
    gcp_address: str
    dataset_path: Path
    date_published: str
    output: str

def datetime_serializer(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

class OtCroissant(Task):
    def __init__(self, spec: OtCroissantSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OtCroissantSpec
        self.local_path: Path = self.context.config.work_path / self.spec.output
        self.remote_uri: str | None = None
        if context.config.release_uri:
            self.remote_uri = f'{context.config.release_uri}/{spec.output}'

    @report
    def run(self) -> Self:
        release = self.context.scratchpad.sentinel_dict.get('release')
        if not release:
            raise ScratchpadError('"release" not found in the scratchpad')
        metadata = PlatformOutputMetadata(
            datasets=[str(self.spec.dataset_path)],
            ftp_location= self.spec.ftp_address,
            gcp_location=self.spec.gcp_address,
            version=release,
            date_published=self.spec.date_published,
            data_integrity_hash='sha256'
        )
        logger.debug(f"Metadata generated: {metadata}")

        with open(self.local_path, "w+") as f:
            metadata_json = metadata.to_json()
            metadata_str = json.dumps(metadata_json, indent=2, default=datetime_serializer)
            content = f'{metadata_str}\n'
            f.write(content)
            logger.debug(f"Metadata written to {self.local_path}")

         # upload the result to remote storage
        if self.remote_uri:
            logger.info(f'Uploading {self.local_path} to {self.remote_uri}')
            remote_storage = get_remote_storage(self.remote_uri)
            remote_storage.upload(self.local_path, self.remote_uri)
            logger.debug('upload successful')
            # set the artifact with the remote output. TODO: set all the inputs for artifact
            self.artifacts = [Artifact(source=f'{self.spec.dataset_path}', destination=str(self.remote_uri))]

        # set the artifact with the local output. TODO: set all the inputs for artifact
        self.artifacts = [Artifact(source=f'{self.spec.dataset_path}', destination=str(self.local_path))]
        return self
