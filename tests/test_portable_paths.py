import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from path_manager import PathManager
from game_manager import GameManager


DEFAULTS = {
    "applications": {
        "steam": "",
        "lutris": "",
        "heroic": "",
        "retroarch": "",
    },
    "steam_library_directories": [],
    "steam_installation_directory": "",
    "rom_directories": [],
    "game_library_directories": [],
    "media_directories": [],
    "retroarch_core_directory": "",
}


class PathManagerTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self.application_directory = self.root / "application"
        (self.application_directory / "config").mkdir(parents=True)
        (self.application_directory / "data").mkdir()
        (self.application_directory / "config" / "defaults.json").write_text(
            json.dumps(DEFAULTS),
            encoding="utf-8",
        )
        self.xdg = {
            "XDG_CONFIG_HOME": str(self.root / "xdg-config"),
            "XDG_DATA_HOME": str(self.root / "xdg-data"),
            "XDG_CACHE_HOME": str(self.root / "xdg-cache"),
            "XDG_STATE_HOME": str(self.root / "xdg-state"),
        }

    def tearDown(self):
        self.temporary_directory.cleanup()

    def test_uses_xdg_directories_and_creates_default_config_once(self):
        with patch.dict(os.environ, self.xdg, clear=False):
            paths = PathManager(self.application_directory)

            self.assertEqual(paths.config_directory, self.root / "xdg-config" / "drn-gaming")
            self.assertEqual(paths.data_directory, self.root / "xdg-data" / "drn-gaming")
            self.assertEqual(paths.cache_directory, self.root / "xdg-cache" / "drn-gaming")
            self.assertEqual(paths.state_directory, self.root / "xdg-state" / "drn-gaming")
            self.assertEqual(json.loads(paths.config_file.read_text()), DEFAULTS)

            paths.config_file.write_text('{"custom": true}', encoding="utf-8")
            PathManager(self.application_directory)
            self.assertEqual(
                json.loads(paths.config_file.read_text()),
                {"custom": True},
            )

    def test_migrates_legacy_data_without_overwriting_user_data(self):
        source = self.application_directory / "data" / "games.json"
        source.write_text('{"games": [{"id": "legacy"}]}', encoding="utf-8")

        with patch.dict(os.environ, self.xdg, clear=False):
            paths = PathManager(self.application_directory)
            migrated = paths.games_file
            self.assertEqual(
                json.loads(migrated.read_text()),
                {"games": [{"id": "legacy"}]},
            )

            migrated.write_text('{"games": [{"id": "newer"}]}', encoding="utf-8")
            PathManager(self.application_directory).games_file
            self.assertEqual(
                json.loads(migrated.read_text()),
                {"games": [{"id": "newer"}]},
            )

    def test_invalid_user_config_is_reported_and_left_untouched(self):
        with patch.dict(os.environ, self.xdg, clear=False):
            paths = PathManager(self.application_directory)
            invalid_contents = '{"applications": []}'
            paths.config_file.write_text(invalid_contents, encoding="utf-8")

            reloaded = PathManager(self.application_directory)

            self.assertTrue(reloaded.configuration_error)
            self.assertEqual(
                reloaded.config_file.read_text(encoding="utf-8"),
                invalid_contents,
            )

    def test_missing_optional_launcher_reports_status_without_crashing(self):
        with patch.dict(os.environ, self.xdg, clear=False):
            paths = PathManager(self.application_directory)
            configuration = dict(paths.configuration)
            configuration["applications"] = {
                **configuration["applications"],
                "heroic": str(self.root / "missing-heroic"),
            }
            paths.save_configuration(configuration)

            with patch.object(GameManager, "sync_steam_games"):
                manager = GameManager(path_manager=paths)

            messages = []
            manager.statusChanged.connect(messages.append)

            self.assertFalse(manager.open_launcher("heroic"))
            self.assertIn("unavailable", messages[-1])

    def test_relative_game_executable_uses_configured_library_directories(self):
        library = self.root / "game-library"
        executable = library / "sample" / "start-game"
        executable.parent.mkdir(parents=True)
        executable.write_text("#!/bin/sh\n", encoding="utf-8")
        executable.chmod(0o755)

        with patch.dict(os.environ, self.xdg, clear=False):
            paths = PathManager(self.application_directory)
            configuration = dict(paths.configuration)
            configuration["game_library_directories"] = [str(library)]
            paths.save_configuration(configuration)

            with patch.object(GameManager, "sync_steam_games"):
                manager = GameManager(path_manager=paths)

            self.assertEqual(
                manager.resolve_game_path("sample/start-game"),
                executable,
            )


if __name__ == "__main__":
    unittest.main()
