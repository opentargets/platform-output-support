import os
from pathlib import Path

import hcl2
from box import Box


def get_config(config_file: str) -> Box:
    dataset_config = Box.from_yaml(filename=config_file)
    return Box(dataset_config, box_dots=True)


def relative_path(path: str | Path, relative_to: str) -> str:
    return os.path.join(os.path.dirname(relative_to), path)


def absolute_path(path: str | Path) -> str:
    return os.path.abspath(str(path))


def parse_hcl(hcl_file: Path) -> dict:
    with open(hcl_file) as f:
        return hcl2.load(f)
