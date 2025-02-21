"""CLI entry point for the application."""

from pathlib import Path
import time
import typer

from .converter import convert
from .utils import setup_logger, LogLevels


CLI_CONTEXT_OPTIONS = {
    "help_option_names": ["-h", "--help"],
    "ignore_unknown_options": True,
}

app = typer.Typer(
    add_completion=False,
    no_args_is_help=True,
    rich_markup_mode="rich",
    context_settings=CLI_CONTEXT_OPTIONS,
)


@app.command("parquet2json", no_args_is_help=True, context_settings=CLI_CONTEXT_OPTIONS)
def parquet2json(
    parquet: str = typer.Argument(help="Input path/URI to parquet."),
    json: Path = typer.Argument(
        help="Output NDJSON path, or leave empty for STDOUT", default=None
    ),
    hive_partitioning: bool = typer.Option(
        help="Use hive partitioning", default=False, show_default=True
    ),
    log_level: LogLevels = typer.Option(
        help="Log level", default="INFO", case_sensitive=False
    ),
) -> None:
    """Convert parquet file to newline delimited JSON."""
    log = setup_logger(log_level.upper())
    start = time.time()
    try:
        convert(
            parquet_path=parquet,
            json_path=json,
            log=log,
            hive_partitioning=hive_partitioning,
        )
        end = time.time()
        elapsed_time = end - start
        log.debug("Converted %s to %s in %.2f seconds.", parquet, json, elapsed_time)
    except Exception as e:
        log.error(e)
        raise typer.Exit(1)


if __name__ == "__main__":
    app()
