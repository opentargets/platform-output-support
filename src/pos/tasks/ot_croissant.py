# OT Croissant Task

from otter.task.model import Spec, Task, TaskContext
from otter.util.errors import OtterError
from otter.task.task_reporter import report

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
        - output (str): The path where the output is going to be stored. The output is a Croissant file witht the metadata of the pipeline execution.
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

    @report
    def run(self) -> None:
        logger.info("Running OT Croissant task")
        metadata = PlatformOutputMetadata(
            datasets=[self.spec.d],
            ftp_location= self.spec.ftp_address,
            gcp_location=self.spec.gcp_address,
            version=self.spec.version,
            date_published=self.spec.date_published,
            data_integrity_hash='sha256'
        )

        with open(self.spec.output, "w") as f:
                content = metadata.to_json()
                content = json.dumps(content, indent=2, default=datetime_serializer)
                f.write(content)
                f.write("\n")
