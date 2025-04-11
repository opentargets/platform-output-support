from abc import ABC, abstractmethod
from functools import wraps
from pathlib import Path
from time import sleep

import docker
import docker.errors
from docker.errors import APIError, ImageNotFound, NotFound
from docker.models.containers import Container
from docker.models.images import Image
from loguru import logger


def reset_timeout(func):
    @wraps(func)
    def wrapper(self, *args, **kwargs):
        self.reset_init_timeout()
        return func(self, *args, **kwargs)

    return wrapper


class ContainerizedServiceError(Exception):
    """Base class for exceptions in this module."""


class ContainerizedService(ABC):
    """Interface for containerized services.

    Args:
        name: Container name
        image: Image name/Dockerfile, can be a string, '<image>:<tag>' or a Path to a Dockerfile
        init_timeout: Initialization timeout in seconds (default: 10)
    """

    DEFAULT_IMAGE_NAME = 'opensearch-pos'

    def __init__(self, name: str, image: str | Path | None = None, init_timeout: int = 10) -> None:
        self.name = name
        self.docker_client = docker.from_env()
        self._image_name = image if isinstance(image, str) else self.DEFAULT_IMAGE_NAME
        self._image = Image()
        self._container = None
        self._init_timeout = init_timeout
        self._init_timeout_reset_value = init_timeout
        if isinstance(image, Path):
            self._build_image(image)

    @property
    def image(self) -> Image:
        try:
            self._image = self.docker_client.images.get(self._image_name)
            return self._image
        except (ImageNotFound, APIError):
            raise ContainerizedServiceError(f'Image {self._image_name} not found')

    @property
    def container(self) -> Container | None:
        try:
            self._container = self.docker_client.containers.get(self.name)
            return self._container
        except NotFound:
            return None

    @container.setter
    def container(self, value: Container) -> None:
        """Set the container property."""
        self._container = value

    @property
    def init_timeout(self) -> int:
        """Get the initialization timeout."""
        return self._init_timeout

    @init_timeout.setter
    def init_timeout(self, value: int) -> None:
        """Set the initialization timeout."""
        self._init_timeout = value

    def reset_init_timeout(self) -> None:
        """Reset the initialization timeout to its original value."""
        self.init_timeout = self._init_timeout_reset_value

    def is_running(self) -> bool:
        """Check if the container is running."""
        try:
            self.docker_client.containers.get(self.name)
            return True
        except NotFound:
            return False

    def stop(self) -> None:
        """Stop the containerized service."""
        if not self.is_running():
            logger.warning(f'{self.name} container is not running')
            return
        logger.debug(f'Stopping {self.name} container')
        self.container.stop()

    def _wait(self, duration: int) -> None:
        """Wait for a specified duration and return the new timeout."""
        logger.debug(f'{self.init_timeout} seconds remaining')
        self.init_timeout -= duration
        sleep(duration)

    def _run_container(
        self,
        ports: dict[str, int | list[int] | tuple[str, int] | None] | None = None,
        env: dict[str, str] | list[str] | None = None,
        volumes: dict[str, dict[str, str]] | None = None,
        **kwargs,
    ) -> None:
        """Run the container.

        Args:
            ports: Ports to expose (default: {None})
            env: Environment variables (default: {None})
            volumes: Volumes to mount (default: {None})
            **kwargs: Additional arguments to pass to the container

        Raises:
            ContainerizedServiceError: If the container fails to start
        """
        if self.is_running():
            logger.warning(f'Container {self.name} is already running')
            return
        if volumes:
            for volume in volumes:
                Path(volume).mkdir(parents=True, exist_ok=True)
        self.container = self.docker_client.containers.run(
            self.image,
            name=self.name,
            auto_remove=True,
            detach=True,
            ports=ports,
            environment=env,
            volumes=volumes,
            **kwargs,
        )
        if not self.is_healthy():
            raise ContainerizedServiceError('Container failed to start')

    def _build_image(self, dockerfile: Path) -> None:
        """Build the image from a Dockerfile.

        Args:
            dockerfile: Path to the Dockerfile

        Raises:
            ContainerizedServiceError: If the image fails to build
        """
        logger.debug('Building image from dockerfile')
        self.docker_client.images.build(path=str(dockerfile.parent), tag=self.DEFAULT_IMAGE_NAME)

    @abstractmethod
    def start(self) -> None:
        """Start the containerized service."""

    @abstractmethod
    def client(self) -> object:
        """Client getter method."""

    @abstractmethod
    @reset_timeout
    def is_healthy(self) -> bool:
        """Check the service is healthy."""
