
import json
import re
import subprocess

from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot

from path_manager import PathManager


class GameManager(QObject):

    gamesChanged = Signal()
    statusChanged = Signal(str)

    def __init__(self, parent=None, path_manager=None):
        super().__init__(parent)

        self.path_manager = path_manager or PathManager()
        self._data_file = self.path_manager.games_file
        self._games = []
        self._game_data_extra = {}
        self._games_load_valid = True

        if self.path_manager.configuration_error:
            self.statusChanged.emit(
                f"Configuration warning: "
                f"{self.path_manager.configuration_error}"
            )

        self.load_games()
        self.sync_steam_games()

    # -------------------------
    # Game Library
    # -------------------------

    @Property("QVariantList", notify=gamesChanged)
    def games(self):
        return self._games

    @Property("QVariantList", notify=gamesChanged)
    def gameLibraryDirectories(self):
        return [
            str(directory)
            for directory in self.path_manager.configured_directories(
                "game_library_directories",
                [],
            )
        ]

    def load_games(self):
        try:
            self._data_file.parent.mkdir(parents=True, exist_ok=True)

            if not self._data_file.exists():
                self._data_file.write_text(
                    '{"games": []}',
                    encoding="utf-8"
                )

            with self._data_file.open("r", encoding="utf-8") as file:
                data = json.load(file)

            if not isinstance(data, dict):
                raise ValueError("Invalid games.json structure")

            games = data.get("games", [])

            if not isinstance(games, list):
                raise ValueError("'games' must be a list")

            if not all(isinstance(game, dict) for game in games):
                raise ValueError("Each game entry must be an object")

            self._games = games
            self._game_data_extra = {
                key: value for key, value in data.items()
                if key != "games"
            }

            self.gamesChanged.emit()

            self.statusChanged.emit(
                f"{len(self._games)} games loaded"
            )

        except (OSError, json.JSONDecodeError, ValueError) as error:
            self._games = []
            self._games_load_valid = False
            self.gamesChanged.emit()

            self.statusChanged.emit(
                f"Library error: {error}"
            )

    def save_games(self):
        if not self._games_load_valid:
            self.statusChanged.emit(
                "Game library is invalid and was left untouched"
            )
            return False

        try:
            self._data_file.parent.mkdir(parents=True, exist_ok=True)

            temp_file = self._data_file.with_suffix(".tmp")

            with temp_file.open("w", encoding="utf-8") as file:
                json.dump(
                    {**self._game_data_extra, "games": self._games},
                    file,
                    indent=4,
                    ensure_ascii=False
                )

            temp_file.replace(self._data_file)
            return True

        except OSError as error:
            self.statusChanged.emit(
                f"Save error: {error}"
            )
            return False

    def resolve_game_path(self, value):
        configured_path = self.path_manager.configured_path(value)
        if configured_path.exists():
            return configured_path

        relative_path = Path(value).expanduser()
        if relative_path.is_absolute():
            return configured_path

        for directory in self.path_manager.configured_directories(
            "game_library_directories",
            [],
        ):
            candidate = directory / relative_path
            if candidate.exists():
                return candidate

        return configured_path

    # -------------------------
    # Steam Library Discovery
    # -------------------------

    def get_steam_roots(self):
        possible_roots = [
            self.path_manager.data_directory.parent / "Steam",
            Path.home() / ".steam" / "debian-installation",
            Path.home() / ".steam" / "steam",
            Path.home() / ".steam" / "root",
            Path.home() / ".local" / "share" / "Steam"
        ]
        configured_installation = self.path_manager.configuration.get(
            "steam_installation_directory",
            "",
        ).strip()
        if configured_installation:
            possible_roots.append(
                self.path_manager.configured_path(configured_installation)
            )
        possible_roots.extend(
            self.path_manager.configured_directories(
                "steam_library_directories",
                [],
            )
        )

        roots = []
        seen = set()

        for root in possible_roots:

            if not root.is_dir():
                continue

            real_root = root.resolve()

            if real_root in seen:
                continue

            seen.add(real_root)
            roots.append(real_root)

        return roots

    def get_steam_libraries(self):

        libraries = set()

        roots = self.get_steam_roots()

        for root in roots:

            libraries.add(root)

            library_file = (
                root / "steamapps" / "libraryfolders.vdf"
            )

            if not library_file.is_file():
                continue

            try:
                content = library_file.read_text(
                    encoding="utf-8",
                    errors="replace"
                )

                paths = re.findall(
                    r'"path"\s*"([^"]+)"',
                    content
                )

                for path in paths:

                    library = Path(path).expanduser()

                    if library.is_dir():
                        libraries.add(library.resolve())

            except OSError:
                continue

        return sorted(libraries)

    @staticmethod
    def read_manifest_value(content, key):

        pattern = rf'"{re.escape(key)}"\s*"([^"]*)"'

        match = re.search(pattern, content)

        if match:
            return match.group(1)

        return None

    @staticmethod
    def is_steam_tool(name, install_dir):

        text = f"{name} {install_dir}".lower()

        excluded_terms = [
            "proton",
            "steam linux runtime",
            "steamlinuxruntime",
            "steamworks common redistributables",
            "pressure-vessel",
            "scout runtime",
            "soldier runtime",
            "sniper runtime"
        ]

        return any(
            term in text for term in excluded_terms
        )

    def scan_steam_games(self):

        discovered_games = {}

        libraries = self.get_steam_libraries()

        for library in libraries:

            steamapps = library / "steamapps"

            if not steamapps.is_dir():
                continue

            manifests = steamapps.glob(
                "appmanifest_*.acf"
            )

            for manifest in manifests:

                try:
                    content = manifest.read_text(
                        encoding="utf-8",
                        errors="replace"
                    )

                    app_id = self.read_manifest_value(
                        content, "appid"
                    )

                    name = self.read_manifest_value(
                        content, "name"
                    )

                    install_dir = self.read_manifest_value(
                        content, "installdir"
                    )

                    state_flags = self.read_manifest_value(
                        content, "StateFlags"
                    )

                    if not all([
                        app_id,
                        name,
                        install_dir,
                        state_flags
                    ]):
                        continue

                    if not app_id.isdigit():
                        continue

                    # StateFlags bit 4 indicates installed.
                    if not (int(state_flags) & 4):
                        continue

                    # Ignore Steam compatibility tools.
                    if self.is_steam_tool(name, install_dir):
                        continue

                    game_path = (
                        steamapps / "common" / install_dir
                    )

                    if not game_path.is_dir():
                        continue

                    game = {
                        "id": f"steam-{app_id}",
                        "name": name,
                        "launcher": "steam",
                        "app_id": app_id,
                        "icon": "🎮",
                        "installed": True,
                        "install_dir": str(game_path),
                        "library_path": str(library)
                    }

                    discovered_games[app_id] = game

                except (OSError, ValueError):
                    continue

        return discovered_games

    @Slot(result=int)
    def sync_steam_games(self):
        if not self._games_load_valid:
            self.statusChanged.emit(
                "Steam scan skipped because the game library file is invalid"
            )
            return 0

        try:
            discovered = self.scan_steam_games()

            existing_games = list(self._games)

            steam_indices = {}

            for index, game in enumerate(self._games):

                if game.get("launcher") == "steam":
                    app_id = str(game.get("app_id", ""))

                    if app_id:
                        steam_indices[app_id] = index

            added = 0
            updated = 0

            for app_id, game in discovered.items():

                if app_id in steam_indices:

                    index = steam_indices[app_id]

                    updated_game = {
                        **self._games[index],
                        **game
                    }

                    if updated_game != self._games[index]:
                        self._games[index] = updated_game
                        updated += 1

                else:
                    self._games.append(game)
                    added += 1

            changed = self._games != existing_games

            if changed:

                if not self.save_games():
                    self._games = existing_games
                    return 0

                self.gamesChanged.emit()

            self.statusChanged.emit(
                f"Steam scan complete: "
                f"{len(discovered)} games found, "
                f"{added} added, {updated} updated"
            )

            return len(discovered)

        except (OSError, ValueError) as error:

            self.statusChanged.emit(
                f"Steam scan failed: {error}"
            )

            return 0

    # -------------------------
    # Add / Remove Games
    # -------------------------

    @Slot("QVariantMap", result=bool)
    def add_game(self, game):

        required = ["id", "name", "launcher"]

        if not all(game.get(key) for key in required):
            self.statusChanged.emit(
                "Game information is incomplete"
            )
            return False

        if any(
            item.get("id") == game["id"]
            for item in self._games
        ):
            self.statusChanged.emit(
                "This game already exists"
            )
            return False

        if game["launcher"] not in (
            "steam", "lutris", "native"
        ):
            self.statusChanged.emit(
                "Unsupported launcher"
            )
            return False

        self._games.append(dict(game))

        if not self.save_games():
            self._games.pop()
            return False

        self.gamesChanged.emit()

        self.statusChanged.emit(
            f"{game['name']} added to library"
        )

        return True

    @Slot(str, result=bool)
    def remove_game(self, game_id):

        for index, game in enumerate(self._games):

            if game.get("id") == game_id:

                removed_game = self._games.pop(index)

                if not self.save_games():
                    self._games.insert(index, removed_game)
                    return False

                self.gamesChanged.emit()

                self.statusChanged.emit(
                    f"{removed_game.get('name', 'Game')} "
                    f"removed from library"
                )

                return True

        self.statusChanged.emit("Game not found")
        return False



    # -------------------------
    # Open Gaming Platforms
    # -------------------------

    @Slot(str, result=bool)
    def open_launcher(self, launcher_name):

        launcher_name = launcher_name.lower().strip()

        launchers = {
            "steam": "steam",
            "lutris": "lutris",
            "heroic": "heroic",
        }

        if launcher_name not in launchers:
            self.statusChanged.emit(
                "Unsupported gaming platform"
            )
            return False

        executable = self.path_manager.application_executable(
            launcher_name
        )

        if not executable:
            self.statusChanged.emit(
                f"{launcher_name.capitalize()} is not installed or "
                "its configured executable is unavailable"
            )
            return False

        try:
            subprocess.Popen([executable])

            self.statusChanged.emit(
                f"Opening {launcher_name.capitalize()}..."
            )

            return True

        except OSError as error:
            self.statusChanged.emit(
                f"Could not open {launcher_name}: {error}"
            )
            return False


    # -------------------------
    # Launch Games
    # -------------------------

    @Slot(str, result=bool)
    def launch_game(self, game_id):

        game = next(
            (
                item for item in self._games
                if item.get("id") == game_id
            ),
            None
        )

        if game is None:
            self.statusChanged.emit("Game not found")
            return False

        launcher = game.get("launcher")

        try:

            # Steam
            if launcher == "steam":

                app_id = str(game.get("app_id", ""))

                if not app_id.isdigit():
                    raise ValueError("Invalid Steam App ID")

                command = self.path_manager.application_executable("steam")

                if not command:
                    raise FileNotFoundError(
                        "Steam executable was not found or is unavailable"
                    )

                subprocess.Popen([
                    command,
                    "-applaunch",
                    app_id
                ])

            # Lutris
            elif launcher == "lutris":

                lutris_id = str(game.get("game_id", ""))

                if not lutris_id:
                    raise ValueError("Invalid Lutris Game ID")

                command = self.path_manager.application_executable("lutris")

                if not command:
                    raise FileNotFoundError(
                        "Lutris executable was not found or is unavailable"
                    )

                subprocess.Popen([
                    command,
                    f"lutris:rungameid/{lutris_id}"
                ])

            # Native Linux Game
            elif launcher == "native":

                executable = game.get("executable", "")

                if not executable:
                    raise ValueError(
                        "Executable path is missing"
                    )

                executable_path = self.resolve_game_path(executable)

                if not executable_path.is_file():
                    raise FileNotFoundError(
                        f"Game executable not found: {executable}"
                    )

                arguments = game.get("args", [])

                if not isinstance(arguments, list):
                    raise ValueError(
                        "Game arguments must be a list"
                    )

                working_directory = game.get(
                    "working_directory"
                )
                if working_directory:
                    working_directory = str(
                        self.resolve_game_path(
                            working_directory
                        )
                    )

                process_command = [
                    str(executable_path),
                    *[str(arg) for arg in arguments]
                ]

                subprocess.Popen(
                    process_command,
                    cwd=(
                        working_directory
                        or str(executable_path.parent)
                    )
                )

            else:
                raise ValueError("Unsupported launcher")

            self.statusChanged.emit(
                f"Launching {game['name']}..."
            )

            return True

        except (OSError, ValueError) as error:

            self.statusChanged.emit(
                f"Launch failed: {error}"
            )

            return False
