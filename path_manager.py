import json
import os
import shutil

from pathlib import Path


APPLICATION_NAME = "drn-gaming"


def _xdg_directory(variable, fallback):
    value = os.environ.get(variable)

    if value:
        path = Path(value).expanduser()
        if path.is_absolute():
            return path

    return Path.home() / fallback


class PathManager:
    def __init__(self, application_dir=None):
        self.application_dir = (
            Path(application_dir).resolve()
            if application_dir
            else Path(__file__).resolve().parent
        )
        self.config_directory = (
            _xdg_directory("XDG_CONFIG_HOME", ".config")
            / APPLICATION_NAME
        )
        self.data_directory = (
            _xdg_directory("XDG_DATA_HOME", ".local/share")
            / APPLICATION_NAME
        )
        self.cache_directory = (
            _xdg_directory("XDG_CACHE_HOME", ".cache")
            / APPLICATION_NAME
        )
        self.state_directory = (
            _xdg_directory("XDG_STATE_HOME", ".local/state")
            / APPLICATION_NAME
        )
        self.config_file = self.config_directory / "config.json"
        self.configuration_error = ""
        self.configuration_valid = True
        self._defaults = self._load_defaults()
        self.configuration = self._load_configuration()

    def _load_defaults(self):
        defaults_file = self.application_dir / "config" / "defaults.json"

        with defaults_file.open("r", encoding="utf-8") as file:
            defaults = json.load(file)

        if not isinstance(defaults, dict):
            raise ValueError("Bundled default configuration must be an object")

        return defaults

    def _load_configuration(self):
        try:
            self.config_directory.mkdir(parents=True, exist_ok=True)

            if not self.config_file.exists():
                self._write_default_configuration()
                return dict(self._defaults)

            with self.config_file.open("r", encoding="utf-8") as file:
                configured = json.load(file)

            if not isinstance(configured, dict):
                raise ValueError("Configuration must be a JSON object")

            result = dict(self._defaults)
            result.update(configured)
            self._validate_configuration(result)
            return result
        except (OSError, json.JSONDecodeError, ValueError) as error:
            self.configuration_error = str(error)
            self.configuration_valid = False
            return dict(self._defaults)

    def _write_default_configuration(self):
        temporary_file = self.config_file.with_suffix(".tmp")
        temporary_file.write_text(
            json.dumps(self._defaults, indent=4, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        temporary_file.replace(self.config_file)

    def save_configuration(self, configuration):
        if not self.configuration_valid:
            raise ValueError(
                "User configuration is invalid and was left untouched"
            )
        self._validate_configuration(configuration)
        self.config_directory.mkdir(parents=True, exist_ok=True)
        temporary_file = self.config_file.with_suffix(".tmp")
        temporary_file.write_text(
            json.dumps(configuration, indent=4, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        temporary_file.replace(self.config_file)
        self.configuration = configuration

    @staticmethod
    def _validate_configuration(configuration):
        applications = configuration.get("applications")
        if not isinstance(applications, dict):
            raise ValueError("'applications' must be an object")

        for name, executable in applications.items():
            if not isinstance(executable, str):
                raise ValueError(
                    f"Application path for '{name}' must be a string"
                )

        for name in (
            "steam_installation_directory",
            "retroarch_core_directory",
        ):
            value = configuration.get(name)
            if not isinstance(value, str):
                raise ValueError(f"'{name}' must be a path string")

        for name in (
            "steam_library_directories",
            "rom_directories",
            "game_library_directories",
            "media_directories",
        ):
            directories = configuration.get(name)
            if not isinstance(directories, list) or not all(
                isinstance(directory, str) for directory in directories
            ):
                raise ValueError(f"'{name}' must be a list of paths")

    def configured_path(self, value):
        path = Path(value).expanduser()
        if not path.is_absolute():
            path = self.config_directory / path
        return path

    def application_executable(self, name):
        value = self.configuration.get("applications", {}).get(name, "").strip()
        if value:
            candidate = self.configured_path(value)
            if candidate.is_dir():
                executable_names = (
                    ("steam", "steam.sh")
                    if name == "steam"
                    else (name,)
                )
                for executable_name in executable_names:
                    executable = candidate / executable_name
                    if executable.is_file() and os.access(executable, os.X_OK):
                        return str(executable)
            if candidate.is_absolute() and (
                candidate.parent != self.config_directory
                or "/" in value
            ):
                if candidate.is_file() and os.access(candidate, os.X_OK):
                    return str(candidate)
                return None

            return shutil.which(value)

        if name == "steam":
            installation = self.configuration.get(
                "steam_installation_directory",
                "",
            ).strip()
            if installation:
                root = self.configured_path(installation)
                for executable_name in ("steam", "steam.sh"):
                    executable = root / executable_name
                    if executable.is_file() and os.access(executable, os.X_OK):
                        return str(executable)

        return shutil.which(name)

    def configured_directories(self, key, fallback):
        values = self.configuration.get(key, [])
        if values:
            return [self.configured_path(value) for value in values]
        return list(fallback)

    def migrate_legacy_file(self, filename, destination):
        source = self.application_dir / "data" / filename
        destination = Path(destination)

        if destination.exists() or not source.is_file():
            return False

        try:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
            return True
        except OSError as error:
            self.configuration_error = (
                f"Could not migrate {source.name}: {error}"
            )
            return False

    @property
    def games_file(self):
        destination = self.data_directory / "games.json"
        self.migrate_legacy_file("games.json", destination)
        return destination

    @property
    def retro_library_file(self):
        destination = self.data_directory / "retro_library.json"
        self.migrate_legacy_file("retro_library.json", destination)
        return destination

    @property
    def retroarch_config_file(self):
        configured = self.configuration.get("applications", {}).get(
            "retroarch_config"
        )
        if configured:
            return self.configured_path(configured)
        return (
            _xdg_directory("XDG_CONFIG_HOME", ".config")
            / "retroarch"
            / "retroarch.cfg"
        )

    @property
    def retroarch_core_directory(self):
        configured = self.configuration.get("retroarch_core_directory")
        if configured:
            return self.configured_path(configured)
        return (
            _xdg_directory("XDG_CONFIG_HOME", ".config")
            / "retroarch"
            / "cores"
        )

    @property
    def rom_directories(self):
        fallback = [self.data_directory / "ROMs"]
        legacy_directory = self.application_dir / "ROMs"
        if legacy_directory.is_dir():
            fallback.insert(0, legacy_directory)
        return self.configured_directories("rom_directories", fallback)

    @property
    def media_directories(self):
        legacy_directory = Path.home() / "Media"
        fallback = (
            [legacy_directory]
            if legacy_directory.is_dir()
            else [self.data_directory / "Media"]
        )
        return self.configured_directories("media_directories", fallback)
