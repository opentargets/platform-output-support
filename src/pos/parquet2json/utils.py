"""Utils"""

import logging
from enum import StrEnum
from logging import Logger

from rich.logging import RichHandler


def setup_logger(loglevel: str) -> Logger:
    """Setup a logger

    Arguments:
        loglevel -- Log level

    Returns:
        Logger
    """
    logging.basicConfig(
        level=loglevel,
        format="%(module)s:%(lineno)d: %(message)s",
        datefmt="[%X]",
        handlers=[RichHandler()],
    )
    return logging.getLogger("rich")


def log_levels() -> list[str]:
    return list(logging.getLevelNamesMapping())


LogLevels = StrEnum("LogLevels", log_levels())
