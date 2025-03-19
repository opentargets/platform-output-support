# OT Croissant Task

import json
from datetime import datetime
from pathlib import Path
from typing import Self
import os

from loguru import logger
from ot_croissant.crumbs.metadata import PlatformOutputMetadata
from otter.manifest.model import Artifact
from otter.storage import get_remote_storage
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError, ScratchpadError
from otter.util.fs import check_dir


class OtCroissantError(OtterError):
    """Base class for exceptions in this module."""


class OtCroissantSpec(Spec):
    """Configuration fields for the OT Croissant task.

    This task has the following custom configuration fields:
        - ftp_address (str): The URL of the ftp where the data \
          is going to be published.
        - gcp_address (str): The URL of the google bucket where \
          the data is going to be published.
        - dataset_path (Path): The path where the parquet outputs \
          are stored. These outputs are going to be used to extract \
          the schema.
        - date_published (str): The date when the data was published. \
          The date format is YYYY-MM-DD.
        - output (str): Path (relative to `work_path` or `release_uri`) \
          to store the metadata at.
    """

    ftp_address: str
    gcp_address: str
    dataset_path: Path
    date_published: str
    output: str


def datetime_serializer(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f'Type {type(obj)} not serializable')


class OtCroissant(Task):
    def __init__(self, spec: OtCroissantSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: OtCroissantSpec
        self.local_path: Path = self.context.config.work_path / self.spec.output
        self.remote_uri: str | None = None
        if context.config.release_uri:
            self.remote_uri = f'{context.config.release_uri}/{self.spec.output}'

    @report
    def run(self) -> Self:
        release = self.context.scratchpad.sentinel_dict.get('release')
        if not release:
            raise ScratchpadError('"release" not found in the scratchpad')

        # Converting the list of paths to a list of strings and prepending the work_path
        logger.debug('converting the list of paths to a list of strings and prepending the work_path')
        # Get the directory path from self.spec.dataset_paths
        directory_path = str(self.context.config.work_path / self.spec.dataset_path)

        # List all sub-folders in the directory
        datasets = [
            str(self.context.config.work_path / self.spec.dataset_path / dataset)
            for dataset in os.listdir(directory_path) if os.path.isdir(os.path.join(directory_path, dataset))
        ]

        logger.debug(f'generating metadata for release {release}')
        metadata = PlatformOutputMetadata(
            datasets=datasets,
            ftp_location=self.spec.ftp_address,
            gcp_location=self.spec.gcp_address,
            version=release,
            date_published=self.spec.date_published,
            data_integrity_hash='sha256',
        )
        logger.debug(f'Metadata generated: {metadata}')

        output_folder = self.local_path.parents[0]
        check_dir(output_folder)

        with open(self.local_path, 'w+') as f:
            logger.debug('writting metadata to localpath')
            metadata_json = metadata.to_json()
            json.dump(metadata_json, f, indent=2, default=datetime_serializer)
            f.write('\n')
            logger.debug(f'metadata written successfully to {self.local_path}')

        # upload the result to remote storage
        if self.remote_uri:
            logger.info(f'uploading {self.local_path} to {self.remote_uri}')
            remote_storage = get_remote_storage(self.remote_uri)
            remote_storage.upload(self.local_path, self.remote_uri)
            logger.debug('metadata upload successful')

        # TODO: set all the inputs for artifact. This has to be done after the functionality is implemented in otter
        self.artifacts = [
            Artifact(
                source=f'{self.spec.gcp_address}',
                destination=self.remote_uri or str(self.local_path),
            )
        ]
        return self
