import json
import os
import re
import shutil
import sysconfig

from pathlib import Path

from PySide6.QtCore import (
    QObject,
    Property,
    Signal,
    Slot,
    QProcess,
)

from path_manager import PathManager


class RetroArchManager(QObject):

    romsChanged = Signal()
    coresChanged = Signal()
    foldersChanged = Signal()
    historyChanged = Signal()

    statusChanged = Signal(str)
    runningChanged = Signal()

    launchStarted = Signal()
    launchFinished = Signal()

    def __init__(self, parent=None, path_manager=None):
        super().__init__(parent)

        self.path_manager = path_manager or PathManager()
        self._data_file = self.path_manager.retro_library_file
        self._rom_directories = self.path_manager.rom_directories
        self._rom_folders = [
            str(directory) for directory in self._rom_directories
        ]
        self._roms = []
        self._cores = []
        self._history = []
        self._selected_cores = {}
        self._settings_extra = {}
        self._settings_valid = True

        if self.path_manager.configuration_error:
            self.statusChanged.emit(
                f"Configuration warning: "
                f"{self.path_manager.configuration_error}"
            )

        self._process = QProcess(self)

        self._process.started.connect(self._on_started)
        self._process.finished.connect(self._on_finished)
        self._process.errorOccurred.connect(self._on_error)

        self._load_settings()

        self.refresh_cores()
        self.scan_roms()
        self.refresh_history()

    # ==================================================
    # Properties
    # ==================================================

    @Property("QVariantList", notify=romsChanged)
    def roms(self):
        return self._roms

    @Property("QVariantList", notify=coresChanged)
    def cores(self):
        return self._cores

    @Property("QVariantList", notify=foldersChanged)
    def romFolders(self):
        return self._rom_folders

    @Property(str, notify=foldersChanged)
    def romDirectory(self):
        return "\n".join(self._rom_folders)

    @Property("QVariantList", notify=historyChanged)
    def history(self):
        return self._history

    @Property(bool, notify=coresChanged)
    def retroArchAvailable(self):
        return self.path_manager.application_executable("retroarch") is not None

    @Property(bool, notify=runningChanged)
    def isRunning(self):
        return (
            self._process.state()
            != QProcess.ProcessState.NotRunning
        )

    @Property(str, notify=coresChanged)
    def preferredCoreDirectory(self):
        return str(self.path_manager.retroarch_core_directory)

    # ==================================================
    # Settings
    # ==================================================

    def _load_settings(self):
        self._rom_folders = [
            str(directory) for directory in self._rom_directories
        ]

        try:
            self._data_file.parent.mkdir(
                parents=True,
                exist_ok=True
            )

            if not self._data_file.exists():
                self._save_settings()
                return

            data = json.loads(
                self._data_file.read_text(encoding="utf-8")
            )

            if not isinstance(data, dict):
                raise ValueError(
                    "Invalid Retro Library settings"
                )

            selected_cores = data.get(
                "selected_cores",
                {}
            )

            if not isinstance(selected_cores, dict):
                raise ValueError("'selected_cores' must be an object")

            if not all(
                isinstance(path, str) and isinstance(core, str)
                for path, core in selected_cores.items()
            ):
                raise ValueError("Selected ROM cores must be string paths")

            self._selected_cores = {
                path: core for path, core in selected_cores.items()
            }
            self._settings_extra = {
                key: value for key, value in data.items()
                if key != "selected_cores"
            }

        except (
            OSError,
            json.JSONDecodeError,
            ValueError
        ) as error:

            self._selected_cores = {}
            self._settings_extra = {}
            self._settings_valid = False

            self.statusChanged.emit(
                f"Retro settings error: {error}"
            )

        self.foldersChanged.emit()

    def _save_settings(self):
        if not self._settings_valid:
            self.statusChanged.emit(
                "Retro settings are invalid and were left untouched"
            )
            return False

        try:
            self._data_file.parent.mkdir(
                parents=True,
                exist_ok=True
            )

            data = {
                **self._settings_extra,
                "selected_cores": self._selected_cores,
            }

            temp_file = self._data_file.with_suffix(".tmp")

            temp_file.write_text(
                json.dumps(
                    data,
                    indent=4,
                    ensure_ascii=False
                ),
                encoding="utf-8"
            )

            temp_file.replace(self._data_file)
            return True

        except OSError as error:
            self.statusChanged.emit(
                f"Retro settings save error: {error}"
            )
            return False

    # ==================================================
    # RetroArch configuration
    # ==================================================

    def _retroarch_config(self):
        return self.path_manager.retroarch_config_file

    @staticmethod
    def _read_config_value(config_file, key):
        if not config_file.is_file():
            return None

        try:
            content = config_file.read_text(
                encoding="utf-8",
                errors="replace"
            )

            match = re.search(
                rf'^\s*{re.escape(key)}\s*=\s*"([^"]*)"',
                content,
                re.MULTILINE
            )

            return match.group(1) if match else None

        except OSError:
            return None

    def _get_core_directories(self):
        directories = [
            self.path_manager.retroarch_core_directory,
            Path("/usr/lib/libretro"),
            Path("/usr/lib64/libretro"),
            Path("/usr/lib/retroarch/cores"),
        ]
        multiarch = sysconfig.get_config_var("MULTIARCH")
        if multiarch:
            directories.append(
                Path("/usr/lib") / multiarch / "libretro"
            )

        configured = self._read_config_value(
            self._retroarch_config(),
            "libretro_directory"
        )

        if configured:
            configured_path = Path(configured).expanduser()

            if not configured_path.is_absolute():
                configured_path = (
                    self._retroarch_config().parent
                    / configured_path
                )

            try:
                preferred_path = (
                    self.path_manager.retroarch_core_directory.resolve()
                )
            except OSError:
                preferred_path = self.path_manager.retroarch_core_directory

            try:
                configured_path = configured_path.resolve()
            except OSError:
                pass

            if configured_path != preferred_path:
                directories.append(configured_path)

        result = []
        seen = set()

        for directory in directories:
            if not directory.is_dir():
                continue

            try:
                resolved = directory.resolve()
            except OSError:
                continue

            if resolved not in seen:
                seen.add(resolved)
                result.append(resolved)

        return result

    def _get_info_directories(self):
        directories = [
            Path("/usr/share/libretro/info"),
            Path("/usr/share/retroarch/cores"),

            self.path_manager.retroarch_core_directory,
            self.path_manager.retroarch_config_file.parent / "info",
        ]

        configured = self._read_config_value(
            self._retroarch_config(),
            "libretro_info_path"
        )

        if configured:
            configured_path = Path(configured).expanduser()
            if not configured_path.is_absolute():
                configured_path = (
                    self.path_manager.retroarch_config_file.parent
                    / configured_path
                )
            directories.append(configured_path)

        result = []
        seen = set()

        for directory in directories:
            if not directory.is_dir():
                continue

            try:
                resolved = directory.resolve()
            except OSError:
                continue

            if resolved not in seen:
                seen.add(resolved)
                result.append(resolved)

        return result

    # ==================================================
    # Core discovery
    # ==================================================

    @staticmethod
    def _read_info_file(info_file):
        try:
            content = info_file.read_text(
                encoding="utf-8",
                errors="replace"
            )
        except OSError:
            return {}

        values = {}

        for key in (
            "display_name",
            "corename",
            "supported_extensions",
        ):
            match = re.search(
                rf'^\s*{key}\s*=\s*"([^"]*)"',
                content,
                re.MULTILINE
            )

            if match:
                values[key] = match.group(1)

        return values

    @Slot(result=int)
    def refresh_cores(self):
        discovered = {}
        info_directories = self._get_info_directories()

        for core_directory in self._get_core_directories():

            try:
                core_files = core_directory.glob(
                    "*_libretro.so"
                )

                for core_file in core_files:
                    info = {}

                    info_filename = (
                        f"{core_file.stem}.info"
                    )

                    for info_directory in info_directories:
                        info_file = (
                            info_directory / info_filename
                        )

                        if info_file.is_file():
                            info = self._read_info_file(
                                info_file
                            )
                            break

                    extensions = info.get(
                        "supported_extensions",
                        ""
                    ).split("|")

                    extensions = [
                        ext.strip().lower().lstrip(".")
                        for ext in extensions
                        if ext.strip()
                    ]

                    name = (
                        info.get("display_name")
                        or info.get("corename")
                        or core_file.stem
                    )

                    try:
                        core_path = str(
                            core_file.resolve()
                        )
                    except OSError:
                        continue

                    discovered[core_path] = {
                        "name": name,
                        "path": core_path,
                        "extensions": extensions,
                    }

            except OSError:
                continue

        self._cores = sorted(
            discovered.values(),
            key=lambda item: item["name"].lower()
        )

        self.coresChanged.emit()

        configured = self._read_config_value(
            self._retroarch_config(),
            "libretro_directory"
        )

        if configured:
            configured_path = Path(
                configured
            ).expanduser()

            try:
                configured_path = configured_path.resolve()
            except OSError:
                pass

            try:
                preferred_path = (
                    self.path_manager.retroarch_core_directory.resolve()
                )
            except OSError:
                preferred_path = self.path_manager.retroarch_core_directory

            if configured_path != preferred_path:
                self.statusChanged.emit(
                    "Notice: RetroArch's configured Core directory "
                    "differs from DRN Gaming's preferred directory."
                )
            else:
                self.statusChanged.emit(
                    f"{len(self._cores)} RetroArch core(s) detected"
                )
        else:
            self.statusChanged.emit(
                f"{len(self._cores)} RetroArch core(s) detected"
            )

        return len(self._cores)

    # ==================================================
    # Fixed ROM directory
    # ==================================================

    @Slot(result=str)
    def get_rom_directory(self):
        return "\n".join(str(directory) for directory in self._rom_directories)

    @Slot(result=bool)
    def open_rom_directory(self):
        directory = self._rom_directories[0]
        try:
            directory.mkdir(parents=True, exist_ok=True)
        except OSError as error:
            self.statusChanged.emit(
                f"Could not create ROM directory: {error}"
            )
            return False

        executable = shutil.which("xdg-open")

        if not executable:
            self.statusChanged.emit(
                "xdg-open was not found"
            )
            return False

        process = QProcess(self)
        process.startDetached(
            executable,
            [str(directory)]
        )

        self.statusChanged.emit(
            "Opening ROM directory"
        )

        return True

    @Slot(str, result=bool)
    def add_rom_folder(self, folder_path):
        directory = self.path_manager.configured_path(folder_path)
        if not directory.is_dir():
            self.statusChanged.emit("ROM directory was not found")
            return False
        if directory in self._rom_directories:
            self.statusChanged.emit("ROM directory is already configured")
            return False
        previous = list(self._rom_directories)
        self._rom_directories.append(directory)
        configuration = dict(self.path_manager.configuration)
        configuration["rom_directories"] = [
            str(item) for item in self._rom_directories
        ]
        try:
            self.path_manager.save_configuration(configuration)
        except (OSError, ValueError) as error:
            self._rom_directories = previous
            self.statusChanged.emit(f"Could not save ROM directories: {error}")
            return False
        self._rom_folders = [
            str(item) for item in self._rom_directories
        ]
        self.foldersChanged.emit()
        self.scan_roms()
        return True

    @Slot(str, result=bool)
    def remove_rom_folder(self, folder_path):
        directory = self.path_manager.configured_path(folder_path)
        if directory not in self._rom_directories:
            self.statusChanged.emit("ROM directory was not found")
            return False
        if len(self._rom_directories) == 1:
            self.statusChanged.emit(
                "At least one ROM directory must remain configured"
            )
            return False
        previous = list(self._rom_directories)
        self._rom_directories.remove(directory)
        configuration = dict(self.path_manager.configuration)
        configuration["rom_directories"] = [
            str(item) for item in self._rom_directories
        ]
        try:
            self.path_manager.save_configuration(configuration)
        except (OSError, ValueError) as error:
            self._rom_directories = previous
            self.statusChanged.emit(f"Could not save ROM directories: {error}")
            return False
        self._rom_folders = [
            str(item) for item in self._rom_directories
        ]
        self.foldersChanged.emit()
        self.scan_roms()
        return True

    # ==================================================
    # ROM discovery
    # ==================================================

    def _compatible_cores(self, extension):
        matches = []

        for core in self._cores:
            if extension in core["extensions"]:
                matches.append({
                    "name": core["name"],
                    "path": core["path"],
                })

        return matches

    @Slot(result=int)
    def scan_roms(self):
        discovered = {}
        scan_errors = []

        supported_extensions = {
            extension
            for core in self._cores
            for extension in core["extensions"]
        }

        def walk_error(error):
            scan_errors.append(str(error))

        for rom_directory in self._rom_directories:
            if not rom_directory.exists():
                if rom_directory == self.path_manager.data_directory / "ROMs":
                    try:
                        rom_directory.mkdir(parents=True, exist_ok=True)
                    except OSError as error:
                        scan_errors.append(f"{rom_directory}: {error}")
                        continue
                else:
                    scan_errors.append(f"ROM directory not found: {rom_directory}")
                    continue

            if not rom_directory.is_dir():
                scan_errors.append(f"ROM path is not a directory: {rom_directory}")
                continue

            for root, _directories, filenames in os.walk(
                rom_directory,
                onerror=walk_error
            ):
                for filename in filenames:
                    file_path = Path(root) / filename

                    extension = (
                        file_path.suffix.lower().lstrip(".")
                    )

                    if extension not in supported_extensions:
                        continue

                    try:
                        resolved = str(file_path.resolve())
                    except OSError as error:
                        scan_errors.append(f"{file_path}: {error}")
                        continue

                    if resolved in discovered:
                        continue

                    compatible = self._compatible_cores(extension)
                    selected = self._selected_cores.get(resolved, "")

                    if not selected:
                        legacy_selection = next(
                            (
                                core_path
                                for old_rom_path, core_path
                                in self._selected_cores.items()
                                if Path(old_rom_path).name == file_path.name
                            ),
                            "",
                        )
                        if legacy_selection:
                            selected = next(
                                (
                                    core["path"]
                                    for core in compatible
                                    if Path(core["path"]).name
                                    == Path(legacy_selection).name
                                ),
                                "",
                            )

                    if not any(
                        core["path"] == selected
                        for core in compatible
                    ):
                        selected = (
                            compatible[0]["path"]
                            if compatible else ""
                        )

                    discovered[resolved] = {
                        "name": file_path.stem,
                        "path": resolved,
                        "extension": extension,
                        "cores": compatible,
                        "selectedCore": selected,
                    }

        self._roms = sorted(
            discovered.values(),
            key=lambda item: item["name"].lower()
        )

        self._rom_folders = [
            str(directory) for directory in self._rom_directories
        ]

        self.romsChanged.emit()
        self.foldersChanged.emit()

        message = f"ROM scan complete: {len(self._roms)} game(s) found"
        if scan_errors:
            message += f"; {len(scan_errors)} path error(s): {scan_errors[0]}"
        self.statusChanged.emit(message)

        return len(self._roms)

    # ==================================================
    # Core selection
    # ==================================================

    @Slot(str, str, result=bool)
    def set_rom_core(self, rom_path, core_path):
        rom = next(
            (
                item for item in self._roms
                if item["path"] == rom_path
            ),
            None
        )

        if rom is None:
            return False

        if not any(
            core["path"] == core_path
            for core in rom["cores"]
        ):
            self.statusChanged.emit(
                "Selected core is not compatible with this ROM"
            )
            return False

        previous = self._selected_cores.get(rom_path)

        self._selected_cores[rom_path] = core_path

        if not self._save_settings():
            if previous is None:
                self._selected_cores.pop(
                    rom_path,
                    None
                )
            else:
                self._selected_cores[rom_path] = previous

            return False

        for item in self._roms:
            if item["path"] == rom_path:
                item["selectedCore"] = core_path
                break

        self.romsChanged.emit()
        return True

    # ==================================================
    # RetroArch history
    # ==================================================

    def _history_file(self):
        config_file = self._retroarch_config()

        configured = self._read_config_value(
            config_file,
            "content_history_path"
        )

        candidates = []

        if configured:
            configured_path = Path(
                configured
            ).expanduser()

            if not configured_path.is_absolute():
                configured_path = (
                    config_file.parent / configured_path
                )

            candidates.append(configured_path)

        candidates.extend([
            self.path_manager.retroarch_config_file.parent
            / "content_history.lpl",

            self.path_manager.retroarch_config_file.parent
            / "playlists"
            / "content_history.lpl",

            self.path_manager.data_directory.parent
            / "retroarch"
            / "content_history.lpl",
        ])

        seen = set()

        for candidate in candidates:
            try:
                resolved = candidate.resolve()
            except OSError:
                continue

            if resolved in seen:
                continue

            seen.add(resolved)

            if resolved.is_file():
                return resolved

        return (
            self.path_manager.retroarch_config_file.parent
            / "content_history.lpl"
        )

    def _find_core_from_history(self, core_path, core_name):
        core_path = str(core_path or "").strip()
        core_name = str(core_name or "").strip()

        if core_path and core_path.upper() != "DETECT":
            candidate = Path(core_path).expanduser()

            if candidate.is_file():
                try:
                    resolved = str(candidate.resolve())
                except OSError:
                    resolved = str(candidate)

                for core in self._cores:
                    if core["path"] == resolved:
                        return core

                return {
                    "name": core_name or candidate.stem,
                    "path": resolved,
                }

        if core_name and core_name.upper() != "DETECT":
            wanted = core_name.casefold()

            for core in self._cores:
                if core["name"].casefold() == wanted:
                    return core

        if core_path:
            filename = Path(core_path).name.casefold()

            for core in self._cores:
                if Path(core["path"]).name.casefold() == filename:
                    return core

        return None

    @Slot(result=int)
    def refresh_history(self):
        history_file = self._history_file()
        entries = []

        try:
            if not history_file.is_file():
                self._history = []
                self.historyChanged.emit()
                return 0

            content = history_file.read_text(
                encoding="utf-8",
                errors="replace"
            )

            data = json.loads(content)

            # RetroArch .lpl files normally contain a JSON array.
            # Older/custom formats may use a dictionary with "items".
            if isinstance(data, list):
                items = data

            elif isinstance(data, dict):
                items = data.get("items", [])

            else:
                raise ValueError(
                    "Unsupported RetroArch history structure"
                )

            if not isinstance(items, list):
                items = []

            seen = set()

            for item in items:
                if not isinstance(item, dict):
                    continue

                raw_path = str(
                    item.get("path", "")
                ).strip()

                if not raw_path:
                    continue

                game_path = Path(
                    raw_path
                ).expanduser()

                try:
                    resolved_path = str(
                        game_path.resolve()
                    )
                except OSError:
                    resolved_path = raw_path

                if resolved_path in seen:
                    continue

                seen.add(resolved_path)

                core = self._find_core_from_history(
                    item.get("core_path", ""),
                    item.get("core_name", "")
                )

                core_path = (
                    core["path"] if core else ""
                )

                core_name = (
                    core["name"]
                    if core else str(
                        item.get("core_name", "Unknown core")
                    )
                )

                label = str(
                    item.get("label", "")
                ).strip()

                if not label:
                    label = game_path.stem

                entries.append({
                    "name": label,
                    "path": resolved_path,
                    "coreName": core_name,
                    "corePath": core_path,
                    "available": game_path.is_file(),
                    "coreAvailable": bool(
                        core_path
                        and Path(core_path).is_file()
                    ),
                })

            self._history = entries
            self.historyChanged.emit()

            self.statusChanged.emit(
                f"History loaded: {len(entries)} game(s)"
            )

            return len(entries)

        except (
            OSError,
            json.JSONDecodeError,
            ValueError
        ) as error:

            self._history = []
            self.historyChanged.emit()

            self.statusChanged.emit(
                f"Could not read RetroArch history: {error}"
            )

            return 0

    # ==================================================
    # Process launching
    # ==================================================

    def _start_process(self, arguments):
        if self.isRunning:
            self.statusChanged.emit(
                "RetroArch is already running"
            )
            return False

        executable = self.path_manager.application_executable("retroarch")

        if not executable:
            self.statusChanged.emit(
                "RetroArch executable was not found"
            )
            return False

        self._process.setProgram(executable)
        self._process.setArguments(arguments)
        self._process.start()

        return True

    @Slot(result=bool)
    def open_menu(self):
        if not self._start_process([
            "--fullscreen",
            "--menu",
        ]):
            return False

        self.statusChanged.emit(
            "Starting RetroArch..."
        )

        return True

    def _launch_with_core(self, game_path, core_path, game_name):
        rom = Path(game_path).expanduser()
        core = Path(core_path).expanduser()

        if not rom.is_file():
            self.statusChanged.emit(
                "ROM file was not found"
            )
            return False

        if not core.is_file():
            self.statusChanged.emit(
                "Selected RetroArch core was not found"
            )
            return False

        if not core.name.endswith("_libretro.so"):
            self.statusChanged.emit(
                "Invalid Libretro core file"
            )
            return False

        if not self._start_process([
            "--fullscreen",
            "-L",
            str(core.resolve()),
            str(rom.resolve()),
        ]):
            return False

        self.statusChanged.emit(
            f"Starting {game_name}..."
        )

        return True

    @Slot(str, str, result=bool)
    def launch_rom(self, rom_path, core_path):
        rom = Path(rom_path).expanduser()
        core = Path(core_path).expanduser()

        if not rom.is_file():
            self.statusChanged.emit(
                "ROM file was not found"
            )
            return False

        if not core.is_file():
            self.statusChanged.emit(
                "Selected RetroArch core was not found"
            )
            return False

        try:
            resolved_core = str(core.resolve())
        except OSError:
            resolved_core = str(core)

        if not any(
            item["path"] == resolved_core
            for item in self._cores
        ):
            self.statusChanged.emit(
                "Core is not registered in Retro Library"
            )
            return False

        return self._launch_with_core(
            str(rom),
            resolved_core,
            rom.stem
        )

    @Slot(str, result=bool)
    def launch_history(self, game_path):
        entry = next(
            (
                item for item in self._history
                if item["path"] == game_path
            ),
            None
        )

        if entry is None:
            self.statusChanged.emit(
                "Game was not found in RetroArch history"
            )
            return False

        if not entry["available"]:
            self.statusChanged.emit(
                "This ROM is no longer available at its saved path"
            )
            return False

        core_path = entry["corePath"]

        if not core_path:
            extension = (
                Path(game_path).suffix.lower().lstrip(".")
            )

            compatible = self._compatible_cores(extension)

            if compatible:
                core_path = compatible[0]["path"]

        if not core_path:
            self.statusChanged.emit(
                "No usable core was found for this game"
            )
            return False

        return self._launch_with_core(
            game_path,
            core_path,
            entry["name"]
        )

    # ==================================================
    # Process events
    # ==================================================

    def _on_started(self):
        self.runningChanged.emit()
        self.launchStarted.emit()

        self.statusChanged.emit(
            "RetroArch is running"
        )

    def _on_finished(self, exit_code, exit_status):
        self.runningChanged.emit()

        self.refresh_history()

        self.launchFinished.emit()

        self.statusChanged.emit(
            f"RetroArch closed (exit code: {exit_code})"
        )

    def _on_error(self, error):
        if error == QProcess.ProcessError.FailedToStart:
            self.runningChanged.emit()

            self.statusChanged.emit(
                "Could not start RetroArch"
            )

            self.launchFinished.emit()