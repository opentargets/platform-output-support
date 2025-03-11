from __future__ import annotations

import sys
import warnings
from typing import Any

from google.api_core.extended_operation import ExtendedOperation
from google.cloud import compute_v1
from loguru import logger


class GCPDiskImage:
    STOPPED_MACHINE_STATUS = (
        compute_v1.Instance.Status.TERMINATED.name,
        compute_v1.Instance.Status.STOPPED.name,
    )

    def __init__(
        self,
        project_id: str,
        zone: str,
        source_disk_name: str,
        image_name: str,
        storage_location: str | None = None,
    ) -> None:
        self.project_id = project_id
        self.zone = zone
        self.source_disk_name = source_disk_name
        self.image_name = image_name
        self.storage_location = storage_location

    def create(self, force: bool = False) -> compute_v1.Image:
        """Creates a new disk image.

        Args:
            force: create the image even if the source disk is attached to a
                running instance.

        Returns:
            An Image object.
        """
        image_client = compute_v1.ImagesClient()
        disk_client = compute_v1.DisksClient()
        instance_client = compute_v1.InstancesClient()

        # Get source disk
        disk = disk_client.get(project=self.project_id, zone=self.zone, disk=self.source_disk_name)

        for disk_user in disk.users:
            instance_name = disk_user.split('/')[-1]
            instance = instance_client.get(project=self.project_id, zone=self.zone, instance=instance_name)
            if instance.status in self.STOPPED_MACHINE_STATUS:
                continue
            if not force:
                raise RuntimeError(
                    f'Instance {disk_user} should be stopped. For Windows instances please '
                    f'stop the instance using `GCESysprep` command. For Linux instances just '
                    f'shut it down normally. You can supress this error and create an image of'
                    f'the disk by setting `force` parameter to true (not recommended). \n'
                    f'More information here: \n'
                    f' * https://cloud.google.com/compute/docs/instances/windows/creating-windows-os-image#api \n'
                    f' * https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images#prepare_instance_for_image'
                )
            else:
                warnings.warn(
                    f'Warning: The `force` option may compromise the integrity of your image. '
                    f'Stop the {disk_user} instance before you create the image if possible.',
                    stacklevel=1,
                )

        # Create image
        image = compute_v1.Image()
        image.source_disk = disk.self_link
        image.name = self.image_name
        if self.storage_location:
            image.storage_locations = [self.storage_location]

        operation = image_client.insert(project=self.project_id, image_resource=image)
        wait_for_extended_operation(operation, 'image creation from disk')

        return image_client.get(project=self.project_id, image=self.image_name)


def wait_for_extended_operation(
    operation: ExtendedOperation, verbose_name: str = 'operation', timeout: int = 300
) -> Any:
    """Waits for the extended (long-running) operation to complete.

    If the operation is successful, it will return its result.
    If the operation ends with an error, an exception will be raised.
    If there were any warnings during the execution of the operation
    they will be printed to sys.stderr.

    Args:
        operation: a long-running operation you want to wait on.
        verbose_name: (optional) a more verbose name of the operation,
            used only during error and warning reporting.
        timeout: how long (in seconds) to wait for operation to finish.
            If None, wait indefinitely.

    Returns:
        Whatever the operation.result() returns.

    Raises:
        This method will raise the exception received from `operation.exception()`
        or RuntimeError if there is no exception set, but there is an `error_code`
        set for the `operation`.

        In case of an operation taking longer than `timeout` seconds to complete,
        a `concurrent.futures.TimeoutError` will be raised.
    """
    result = operation.result(timeout=timeout)

    if operation.error_code:
        logger.error(
            f'Error during {verbose_name}: [Code: {operation.error_code}]: {operation.error_message}',
            file=sys.stderr,
            flush=True,
        )
        logger.error(f'Operation ID: {operation.name}', file=sys.stderr, flush=True)
        raise operation.exception() or RuntimeError(operation.error_message)

    if operation.warnings:
        logger.warning(f'Warnings during {verbose_name}:\n', file=sys.stderr, flush=True)
        for warning in operation.warnings:
            logger.warning(f' - {warning.code}: {warning.message}', file=sys.stderr, flush=True)

    return result
