import socket
import subprocess
import time

from loguru import logger


class ComputeEngineSSHTunnelError(Exception):
    """Exception for Compute Engine SSH Tunnel-related errors."""


class ComputeEngineSSHTunnel:
    def __init__(
        self, instance_name: str, zone: str, project: str, local_port: int, remote_port: int, timeout: int = 5
    ) -> None:
        """Initializes the ComputeEngineSSHTunnel.

        A context manager for establishing an SSH tunnel to a GCP Compute Engine instance.

        Args:
            instance_name (str): Name of the Compute Engine instance.
            zone (str): Zone of the Compute Engine instance.
            project (str): GCP project ID.
            local_port (int): Local port to bind the tunnel.
            remote_port (int): Remote port on the instance to forward to.
            timeout (int): Timeout in seconds for establishing the tunnel.
        """
        self._instance_name = instance_name
        self._zone = zone
        self._project = project
        self._local_port = local_port
        self._remote_port = remote_port
        self._timeout = timeout
        self._proc = None

    def __enter__(self) -> None:
        return self.ssh_tunnel()

    def __exit__(self, exc_type, exc_value, traceback) -> None:
        if self._proc:
            self._proc.terminate()
            self._proc.wait()

    def ssh_tunnel(self) -> None:
        command = [
            'gcloud',
            'compute',
            'ssh',
            self._instance_name,
            '--zone',
            self._zone,
            '--project',
            self._project,
            '--tunnel-through-iap',
            '--',
            f'-L {self._local_port}:localhost:{self._remote_port}',
            '-N',
        ]
        try:
            self._proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if self._port_is_open():
                return
            else:
                self._proc.terminate()
                self._proc.wait()
                raise ComputeEngineSSHTunnelError(
                    f'Failed to establish SSH tunnel to {self._instance_name} on port {self._local_port}'
                )
        except Exception as e:
            raise ComputeEngineSSHTunnelError(f'gcloud command {" ".join(command)} failed: {e}') from e

    def _port_is_open(self) -> bool:
        logger.debug(f'Checking if port {self._local_port} is open...')
        is_connected = False
        while self._timeout > 0 and not is_connected:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                if sock.connect_ex(('localhost', self._local_port)) == 0:
                    logger.info(f'port {self._local_port} is open')
                    is_connected = True
                else:
                    logger.debug(f'port {self._local_port} is not open, retrying...')
                    time.sleep(1)
                    self._timeout -= 1
        return is_connected
