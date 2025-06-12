from collections.abc import Iterable, Sequence
from pathlib import Path
from typing import Any

from google.cloud import bigquery
from google.cloud.bigquery import external_config
from google.cloud.bigquery.schema import SchemaField
from loguru import logger


class BigQuery:
    """BigQuery client wrapper.

    Attributes:
        _client: BigQuery client
        _dataset: Dataset name

    Args:
        project: GCP project ID
        location: GCP location
        dataset: Dataset name (a bq dataset is a container for tables)

    """

    def __init__(self, project: str, location: str, dataset: str) -> None:
        self._client = bigquery.Client(project=project, location=location)
        self._dataset = dataset

    def load_from_uri(self, path: str, table: str, format: str, hive_partition_source: Path | None = None) -> None:
        """Load data from a URI into a table.

        Args:
            path (str): URI of the data
            table (str): Table name
            format (str): Data format
            hive_partition_source (Path|None): Optional source URI for Hive partitioning
        """
        logger.debug(f'loading {path} into {self.table_name(table)}')
        if hive_partition_source:
            hive_partioning_options = external_config.HivePartitioningOptions()
            hive_partioning_options.mode = 'STRINGS'
            hive_partioning_options.source_uri_prefix = str(hive_partition_source)
            self._client.load_table_from_uri(
                path,
                self.table_name(table),
                job_config=bigquery.LoadJobConfig(
                    autodetect=True,
                    source_format=format,
                    hive_partitioning=hive_partioning_options,
                ),
            )
        self._client.load_table_from_uri(
            path, self.table_name(table), job_config=bigquery.LoadJobConfig(autodetect=True, source_format=format)
        )

    def load_from_json(self, data: Iterable[dict[str, Any]], table: str, schema: Sequence[SchemaField]) -> None:
        """Load data from a JSON object into a table.

        Args:
            data (Iterable[dict[str, Any]]): JSON object
            table (str): Table name
            schema (Sequence[SchemaField]): Table schema
        """
        self._client.load_table_from_json(
            data, self.table_name(table), job_config=bigquery.LoadJobConfig(schema=schema)
        )

    def delete_dataset(self) -> None:
        """Delete the dataset and its contents."""
        self._client.delete_dataset(self._dataset, delete_contents=True, not_found_ok=True)

    def create_dataset(self) -> None:
        """Create the dataset (container for tables).

        If the dataset exists already, it will delete it and then recreate it.
        """
        self.delete_dataset()
        self._client.create_dataset(self._dataset, exists_ok=True)

    def create_table(self, table: str) -> None:
        """Create a table.

        Args:
            table: Table name
        """
        self._client.create_table(self.table_name(table))

    def table_name(self, table: str) -> str:
        """Return the fully qualified table name.

        Args:
            table: Table name

        Returns:
            Fully qualified table name
        """
        return f'{self._dataset}.{table}'

    def make_dataset_access_public(self) -> None:
        """Make the dataset public.

        Sets the dataset access to allAuthenticatedUsers with READ and metadataViewer roles.
        """
        dataset = self._client.get_dataset(self._dataset)
        access_entries = dataset.access_entries
        access_entries.append(
            bigquery.AccessEntry(
                role='roles/bigquery.metadataViewer', entity_type='specialGroup', entity_id='allAuthenticatedUsers'
            )
        )
        access_entries.append(
            bigquery.AccessEntry(role='READER', entity_type='specialGroup', entity_id='allAuthenticatedUsers')
        )
        dataset.access_entries = access_entries
        self._client.update_dataset(dataset, ['access_entries'])
