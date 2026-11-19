
import sys

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

from game_manager import GameManager
from system_manager import SystemManager
from retroarch_manager import RetroArchManager
from media_manager import MediaManager
from path_manager import PathManager


app = QGuiApplication(sys.argv)

engine = QQmlApplicationEngine()
path_manager = PathManager()

# =========================================================
# Managers
# =========================================================

game_manager = GameManager(path_manager=path_manager)
system_manager = SystemManager()
retroarch_manager = RetroArchManager(path_manager=path_manager)
media_manager = MediaManager(path_manager=path_manager)

# =========================================================
# Expose managers to QML
# =========================================================

engine.rootContext().setContextProperty(
    "GameManager",
    game_manager
)

engine.rootContext().setContextProperty(
    "SystemManager",
    system_manager
)

engine.rootContext().setContextProperty(
    "RetroArchManager",
    retroarch_manager
)

engine.rootContext().setContextProperty(
    "MediaManager",
    media_manager
)

# =========================================================
# Forward status messages
# =========================================================

system_manager.statusChanged.connect(
    lambda message: game_manager.statusChanged.emit(message)
)

retroarch_manager.statusChanged.connect(
    lambda message: game_manager.statusChanged.emit(message)
)

media_manager.statusChanged.connect(
    lambda message: game_manager.statusChanged.emit(message)
)

# =========================================================
# Load interface
# =========================================================

qml_file = (
    path_manager.application_dir
    / "qml"
    / "main.qml"
)

engine.load(
    QUrl.fromLocalFile(str(qml_file))
)

if not engine.rootObjects():
    sys.exit(-1)

sys.exit(app.exec())
