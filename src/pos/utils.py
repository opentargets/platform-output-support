from pathlib import Path

import hcl2
from box import Box


def get_config(config_file: str) -> Box:
    dataset_config = Box.from_yaml(filename=config_file)
    return Box(dataset_config, box_dots=True)


def parse_hcl(hcl_file: Path) -> dict:
    with open(hcl_file) as f:
        return hcl2.load(f)
