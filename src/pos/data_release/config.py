"""CLI to parse HCL and YAML files.

Update the YAML file with values from the HCL file.
Key value pairs indicate which values in the yaml to update
with which values in the HCL file.
"""

import sys
from pathlib import Path

import typer
from box import Box
from typer import Argument, Option

from pos.utils import get_config, parse_hcl

app = typer.Typer(
    add_completion=False,
    no_args_is_help=True,
    rich_markup_mode='rich',
    context_settings={'help_option_names': ['-h', '--help']},
)


@app.command(
    no_args_is_help=True,
    context_settings={'help_option_names': ['-h', '--help'], 'allow_extra_args': True, 'ignore_unknown_options': True},
)
def hcl(
    yaml_file: Path = Argument(..., readable=True, help='Path to the YAML file'),
    hcl: Path = Option(None, readable=True, help='Path to the HCL file'),
    output: Path = Option(
        None,
        help='Path to the output YAML file. If not provided, the output goes to stdout.',
    ),
    variables: typer.Context = Option(
        None,
        help=(
            'Key value pairs to update the YAML file with values from the HCL file using the `--<FIELD>=<VALUE>` format'
        ),
    ),
) -> None:
    yaml_config = get_config(str(yaml_file))
    variable_dict = dict_from_args(variables.args) if variables else {}
    if hcl:
        hcl_config = parse_hcl(hcl)
        yaml_config = update_from_hcl(yaml_config, hcl_config, variable_dict)
    else:
        # If no HCL file is provided, update the YAML config with the provided key-value pairs
        for key, value in variable_dict.items():
            if key not in yaml_config:
                raise ValueError(f"Key '{key}' not found in the YAML file")
            yaml_config[key] = value
    config = yaml_config.to_yaml(output, default_flow_style=False)
    if output is None:
        sys.stdout.write(config)


def update_from_hcl(config: Box, hcl_config: dict, variables: dict) -> Box:
    for key, value in variables.items():
        config[key] = hcl_config[value]
    return config


def dict_from_args(args: list) -> dict:
    """Generate a dict from cli args split on "=".

    Arguments:
        args -- cli args list

    Returns:
        Dict of key, values
    """
    variables = {}
    for arg in args:
        if '=' not in arg:
            pass
        else:
            key, value = arg.replace('--', '').split('=')
            variables[key] = value
    return variables


if __name__ == '__main__':
    app()
