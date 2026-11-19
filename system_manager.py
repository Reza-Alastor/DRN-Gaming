
import os
import shutil
import subprocess

from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot


class SystemManager(QObject):
    """Launches desktop utilities, web applications and session actions."""

    statusChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)

    # ==================================================
    # General application launcher
    # ==================================================

    def _start(self, executable, arguments=None):
        """
        Launch an application using either:
        - An executable name available in PATH
        - An absolute or relative executable path
        """

        executable_path = Path(executable).expanduser()

        if executable_path.is_absolute() or "/" in executable:
            if (
                not executable_path.is_file()
                or not os.access(executable_path, os.X_OK)
            ):
                self.statusChanged.emit(
                    f"{executable} is not executable or does not exist"
                )
                return False

            command = str(executable_path)

        else:
            command = shutil.which(executable)

            if not command:
                self.statusChanged.emit(
                    f"{executable} is not installed or not in PATH"
                )
                return False

        try:
            subprocess.Popen(
                [command, *(arguments or [])]
            )
            return True

        except OSError as error:
            self.statusChanged.emit(
                f"Could not open {executable}: {error}"
            )
            return False

    # ==================================================
    # Application discovery and launcher
    # ==================================================

    def _start_candidates(self, label, executables=None, paths=None):
        """Find and launch the first available executable."""

        candidates = []

        # Search executable names in PATH.
        for executable in executables or []:
            found = shutil.which(executable)

            if found:
                candidates.append(Path(found))

        # Search known executable paths.
        for path in paths or []:
            candidate = Path(path).expanduser()

            if (
                candidate.is_file()
                and os.access(candidate, os.X_OK)
            ):
                candidates.append(candidate)

        # Remove duplicate paths while preserving order.
        unique_candidates = list(dict.fromkeys(candidates))

        for candidate in unique_candidates:
            try:
                subprocess.Popen([str(candidate)])

                self.statusChanged.emit(
                    f"Opening {label}..."
                )

                return True

            except OSError:
                continue

        self.statusChanged.emit(
            f"Could not find or launch {label}. "
            "Check its installation and executable path."
        )

        return False

    # ==================================================
    # Web applications
    # ==================================================

    @Slot(str, result=bool)
    def open_web_app(self, app_name):
        app_name = app_name.strip().lower()

        # ----------------------------------------------
        # Google Chrome
        # ----------------------------------------------

        if app_name == "chrome":
            success = self._start_candidates(
                "Google Chrome",

                executables=[
                    "google-chrome",
                    "google-chrome-stable",
                    "chrome",
                ],
            )

            # Flatpak fallback.
            if not success and shutil.which("flatpak"):
                success = self._start(
                    "flatpak",
                    ["run", "com.google.Chrome"]
                )

                if success:
                    self.statusChanged.emit(
                        "Opening Google Chrome..."
                    )

            return success

        # ----------------------------------------------
        # Arman VPN
        # ----------------------------------------------

        if app_name == "arman-vpn":
            return self._start_candidates(
                "Arman VPN",

                executables=[
                    "arman-vpn",
                    "arman-vpn-tun",
                ],
            )

        self.statusChanged.emit(
            f"Unknown web application: {app_name}"
        )

        return False

    # ==================================================
    # System Hub applications
    # ==================================================

    @Slot(str, result=bool)
    def open_tool(self, tool_name):
        tool_name = tool_name.strip().lower()

        tools = {
            "terminal": ("konsole", []),
            "settings": ("systemsettings", []),
            "files": ("dolphin", []),
            "display": ("systemsettings", ["kcm_kscreen"]),
            "audio": ("systemsettings", ["kcm_pulseaudio"]),
            "network": ("systemsettings", ["kcm_networkmanagement"]),
            "controller": ("systemsettings", []),
        }

        if tool_name not in tools:
            self.statusChanged.emit(
                "Unknown System Hub action"
            )
            return False

        executable, arguments = tools[tool_name]

        success = self._start(
            executable,
            arguments
        )

        # Fallback for KDE modules.
        if not success and tool_name in (
            "display",
            "audio",
            "network"
        ):
            success = self._start("systemsettings")

            if success:
                self.statusChanged.emit(
                    f"Opened System Settings; locate "
                    f"{tool_name} settings there"
                )
                return True

        if success:
            messages = {
                "terminal": "Opening Terminal...",
                "settings": "Opening System Settings...",
                "files": "Opening File Manager...",
                "display": "Opening Display settings...",
                "audio": "Opening Audio settings...",
                "network": "Opening Network settings...",
                "controller": "Opening System Settings · Input Devices",
            }

            self.statusChanged.emit(
                messages[tool_name]
            )

        return success

    # ==================================================
    # Power actions
    # ==================================================

    @Slot(str, result=bool)
    def power_action(self, action):
        action = action.strip().lower()

        # ----------------------------------------------
        # Logout
        # ----------------------------------------------

        if action == "logout":
            success = self._start(
                "qdbus6",
                [
                    "org.kde.ksmserver",
                    "/KSMServer",
                    "logout",
                    "0",
                    "0",
                    "0",
                ]
            )

            if not success:
                self.statusChanged.emit(
                    "Could not request KDE logout; "
                    "use the desktop session menu"
                )

            return success

        # ----------------------------------------------
        # Restart / Shutdown
        # ----------------------------------------------

        if action == "restart":
            command = "reboot"

        elif action == "shutdown":
            command = "poweroff"

        else:
            self.statusChanged.emit(
                "Unknown power action"
            )
            return False

        success = self._start(
            "systemctl",
            [command]
        )

        if success:
            self.statusChanged.emit(
                "Restart requested..."
                if action == "restart"
                else "Shutdown requested..."
            )

        return success
