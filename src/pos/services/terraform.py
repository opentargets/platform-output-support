import subprocess
from enum import Enum
from pathlib import Path
from subprocess import CompletedProcess


class TerraformError(Exception):
    """Exception for Terraform-related errors."""


class WorkspaceAction(Enum):
    SELECT = 'select'
    NEW = 'new'
    DELETE = 'delete'


class TerraformRunner:
    def __init__(self, tfdir: Path) -> None:
        """Initializes the TerraformRunner.

        A wrapper for executing Terraform commands.

        Args:
            tfdir (Path): Path to the Terraform directory.
        """
        self.tfdir = tfdir

    def init(self) -> CompletedProcess[bytes]:
        return self._command('init')

    def workspace(self, action: WorkspaceAction, name: str) -> CompletedProcess[bytes]:
        return self._command('workspace', [action.value, name])

    def apply(
        self, tfvars: dict[str, str] | None, tfvar_file: Path | None, auto_approve: bool = False
    ) -> CompletedProcess[bytes]:
        args = ['-auto-approve'] if auto_approve else []
        args = self._add_tvars_to_args(args, tfvars)
        args = self._add_tvar_file_to_args(args, tfvar_file)
        return self._command('apply', args)

    def destroy(self, auto_approve: bool = False) -> CompletedProcess[bytes]:
        return self._command('destroy', ['-auto-approve'] if auto_approve else None)

    def _command(self, command: str, args: list[str] | None = None) -> CompletedProcess[bytes]:
        tf_command = ['terraform', '-chdir=' + str(self.tfdir)]
        tf_command.append(command)
        if args:
            tf_command.extend(args)
        try:
            process = subprocess.run(tf_command, check=True)
        except subprocess.CalledProcessError as e:
            raise TerraformError(f'Terraform command {" ".join(tf_command)} failed: {e}') from e
        if process.returncode != 0:
            raise TerraformError(f'Terraform command {" ".join(tf_command)} failed with exit code {process.returncode}')
        return process

    def _add_tvars_to_args(self, args: list[str], tfvars: dict[str, str] | None) -> list[str]:
        if tfvars:
            for key, value in tfvars.items():
                args.append(f'-var={key}={value}')
        return args

    def _add_tvar_file_to_args(self, args: list[str], tfvar_file: Path | None) -> list[str]:
        if tfvar_file:
            args.append(f'-var-file={tfvar_file}')
        return args
