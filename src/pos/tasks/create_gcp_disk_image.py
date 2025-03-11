# Data prep task


import subprocess
from pathlib import Path
from typing import Self

from loguru import logger
from otter.task.model import Spec, Task, TaskContext
from otter.task.task_reporter import report
from otter.util.errors import OtterError

from pos.gcp.disk_image import GCPDiskImage


class CreateGcpDiskImageError(OtterError):
    """Base class for exceptions in this module."""


class CreateGcpDiskImageSpec(Spec):
    """Configuration fields for the GCP Disk Image task."""

    mount_point: Path = '/mnt/opensearch'  # '/mnt/opensearch or /mnt/clickhouse'
    gcp_project_id: str
    gcp_disk_name: str
    gcp_image_name: str  # 'dev-250310-os or dev-250310-ch'
    gcp_disk_zone: str  # 'europe-west1-d'
    gcp_storage_location: str = 'eu'
    # gcp_image_family: str  # 'ot-os2 or ot-ch'
    gcp_image_labels_team: str = 'open-targets'
    gcp_image_labels_subteam: str = 'backend'
    gcp_image_labels_product: str = 'platform'
    gcp_image_labels_tool: str = 'pos'


class CreateGcpDiskImage(Task):
    def __init__(self, spec: CreateGcpDiskImageSpec, context: TaskContext) -> None:
        super().__init__(spec, context)
        self.spec: CreateGcpDiskImageSpec

    @report
    def run(self) -> Self:
        # self._unmount_disk()
        gcp_disk_image = GCPDiskImage(
            project_id=self.spec.gcp_project_id,
            zone=self.spec.gcp_disk_zone,
            source_disk_name=self.spec.gcp_disk_name,
            image_name=self.spec.gcp_image_name,
            storage_location=self.spec.gcp_storage_location,
        )
        try:
            gcp_disk_image.create(force=True)
        except (RuntimeError, TimeoutError) as e:
            raise CreateGcpDiskImageError(f'Failed to create GCP disk image: {e}')
        return self

    def _unmount_disk(self):
        unmount_status = subprocess.run(['umount', self.spec.mount_point], timeout=60)
        if unmount_status.returncode != 0:
            raise CreateGcpDiskImageError(f'Failed to unmount {self.spec.mount_point}')


"""
function create_gcp_image() {
    local gcp_disk_name=$1
    local gcp_disk_zone=$2
    local gcp_image_name=$3
    local gcp_image_family=$4
    local gcp_image_labels=$5
    local gcp_snapshot_name="${gcp_disk_name}-snapshot"

    log "[START] Creating GCP snapshot '${gcp_snapshot_name}' from GCP disk '${gcp_disk_name}' in zone '${gcp_disk_zone}'"
    gcloud compute disks snapshot ${gcp_disk_name} \
        --zone ${gcp_disk_zone} \
        --snapshot-names ${gcp_snapshot_name}
    log "[DONE] Creating GCP snapshot '${gcp_snapshot_name}' from GCP disk '${gcp_disk_name}' in zone '${gcp_disk_zone}'"

    log "[START] Creating GCP image '${gcp_image_name}' from GCP snapshot '${gcp_snapshot_name}'"
    gcloud compute images create ${gcp_image_name} \
        --source-snapshot ${gcp_snapshot_name} \
        --family ${gcp_image_family} \
        --labels ${gcp_image_labels}
    log "[DONE] Creating GCP image '${gcp_image_name}' from GCP snapshot '${gcp_snapshot_name}'"

    log "[START] Deleting GCP snapshot '${gcp_snapshot_name}'"
    gcloud compute snapshots delete ${gcp_snapshot_name} --quiet
    log "[DONE] Deleting GCP snapshot '${gcp_snapshot_name}'"
    
    
    
    disk_image_labels_ch = join(",", formatlist("%s=%s", keys(local.base_labels), values(local.base_labels)))

  // --- Labels Configuration --- //
  base_labels = {
    "team"    = "open-targets"
    "subteam" = "backend"
    "product" = "platform"
    "tool"    = "pos"
  }
"""
