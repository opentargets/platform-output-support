from otter.config.yaml import parse_yaml
from pathlib import Path
from box import Box


def get_config(config_file: str) -> Box:
    dataset_config = parse_yaml(Path(config_file))
    return Box(dataset_config)
