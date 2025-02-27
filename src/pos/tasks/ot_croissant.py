# OT Croissant Task

from pathlib import Path
from typing import Self

from otter.task.model import Spec, Task, TaskContext
from otter.util.errors import OtterError
from otter.task.task_reporter import report
from otter.storage import get_remote_storage

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
        - d (str): The path where the parquet outputs are stored. These outputs are going to be used to extract the schema.
        - version (str): The version of the data.
        - date_published (str): The date when the data was published. The date format is YYYY-MM-DD.
        - output (str): Name of the file where the metadata is going to be stored.
    """

    ftp_address: str
    gcp_address: str
    d: str
    version: str
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
        metadata = PlatformOutputMetadata(
            datasets=[self.spec.d],
            ftp_location= self.spec.ftp_address,
            gcp_location=self.spec.gcp_address,
            version=self.spec.version,
            date_published=self.spec.date_published,
            data_integrity_hash='sha256'
        )
        logger.debug(f"Metadata generated: {metadata}")

        with open(self.local_path, "w") as f:
                content = metadata.to_json()
                content = json.dumps(content, indent=2, default=datetime_serializer)
                f.write(content)
                f.write("\n")
                logger.debug(f"Metadata written to {self.local_path}")

         # upload the result to remote storage
        if self.remote_uri:
            logger.info(f'Uploading {self.local_path} to {self.remote_uri}')
            remote_storage = get_remote_storage(self.remote_uri)
            remote_storage.upload(self.local_path, self.remote_uri)
            logger.debug('upload successful')

        return self
