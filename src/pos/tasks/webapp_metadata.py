# Webapp Metadata Task
from typing import Self

from otter.task.model import Spec, Task, TaskContext
from otter.util.errors import OtterError
from otter.task.task_reporter import report

from loguru import logger

import polars as pl

class WebappMetadataError(OtterError):
    """Base class for exceptions in this module."""

class WebappMetadataSpec(Spec):
    """Configuration fields for the Webapp Metadata task.

    This task has the following custom configuration fields:
        - metadata_path (str): The path where the metadata in Croissant format is stored.
        - output (str): The path where metadata file is going to be stored.
    """

    metadata_path: str
    output: str

class WebappMetadata(Task):
    def __init__(self, spec: WebappMetadataSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: WebappMetadataSpec

    @report
    def run(self) -> Self:
        # read metadata in Croissant format using polars
        metadata_croissant = pl.read_json(self.spec.metadata_path)
        # read output files
        distributions = metadata_croissant.select('distribution').explode('distribution').unnest('distribution').filter(pl.col('@type') =="cr:FileSet").select(id=pl.col('@id').str.split('-').list.first(), format=pl.col('encodingFormat'), path=pl.col('includes'))
        # get schemas
        record_sets =metadata_croissant.select('recordSet').explode('recordSet').unnest('recordSet').select(id=pl.col('@id'), field=pl.col("field"))
        #join distributions with schemas
        joined = distributions.join(record_sets, on=["id"], how='inner')
        # build resource
        downloads = joined.select(
            pl.col("id"),
            resource = pl.struct(
                format=pl.col("format").str.replace("application/","").str.split("-").list.last(),
                path=pl.col("path").str.split("/").list.slice(0,pl.col("path").str.split("/").list.len()-1).list.join("/"),
                generateMetadata=True))
        print(f"Found {downloads} distributions")
        # transform schemas
        return self
