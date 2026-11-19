
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, QUrl
from PySide6.QtGui import QDesktopServices

from path_manager import PathManager


class MediaManager(QObject):

    mediaChanged = Signal()
    statusChanged = Signal(str)

    VIDEO_EXTENSIONS = {
        ".mp4", ".mkv", ".avi", ".mov", ".webm",
        ".m4v", ".mpeg", ".mpg", ".3gp", ".ts"
    }

    MUSIC_EXTENSIONS = {
        ".mp3", ".flac", ".wav", ".ogg", ".m4a",
        ".aac", ".opus", ".wma", ".aiff", ".mid", ".midi"
    }

    IMAGE_EXTENSIONS = {
        ".png", ".jpg", ".jpeg", ".webp", ".gif",
        ".bmp", ".tiff", ".tif", ".svg", ".avif"
    }

    def __init__(self, path_manager=None):
        super().__init__()

        self.path_manager = path_manager or PathManager()
        self._media_directories = self.path_manager.media_directories

        self._media_files = []
        self._videos = []
        self._music = []
        self._images = []

        # Periodically check for new, removed or modified files.
        self._timer = QTimer(self)
        self._timer.setInterval(4000)
        self._timer.timeout.connect(self.scan)
        self._timer.start()

        self.scan()

    @Property("QVariantList", notify=mediaChanged)
    def mediaFiles(self):
        return self._media_files

    @Property("QVariantList", notify=mediaChanged)
    def videos(self):
        return self._videos

    @Property("QVariantList", notify=mediaChanged)
    def music(self):
        return self._music

    @Property("QVariantList", notify=mediaChanged)
    def images(self):
        return self._images

    @Property(str, notify=mediaChanged)
    def mediaDirectory(self):
        return str(self._media_directories[0])

    @Property("QVariantList", notify=mediaChanged)
    def mediaDirectories(self):
        return [str(directory) for directory in self._media_directories]

    @Property(int, notify=mediaChanged)
    def totalCount(self):
        return len(self._media_files)

    @Property(int, notify=mediaChanged)
    def videoCount(self):
        return len(self._videos)

    @Property(int, notify=mediaChanged)
    def musicCount(self):
        return len(self._music)

    @Property(int, notify=mediaChanged)
    def imageCount(self):
        return len(self._images)

    def _get_media_type(self, extension):
        extension = extension.lower()

        if extension in self.VIDEO_EXTENSIONS:
            return "VIDEO"

        if extension in self.MUSIC_EXTENSIONS:
            return "MUSIC"

        if extension in self.IMAGE_EXTENSIONS:
            return "IMAGE"

        return None

    def _format_size(self, size):
        units = ["B", "KB", "MB", "GB", "TB"]
        value = float(size)

        for unit in units:
            if value < 1024 or unit == units[-1]:
                return f"{value:.1f} {unit}"

            value /= 1024

        return f"{value:.1f} TB"

    @Slot()
    def scan(self):
        media_files = []
        videos = []
        music = []
        images = []
        failures = []

        for media_directory in self._media_directories:
            try:
                media_directory.mkdir(parents=True, exist_ok=True)
                files = media_directory.rglob("*")
            except OSError as error:
                failures.append(f"{media_directory}: {error}")
                continue

            for file_path in files:
                try:
                    if not file_path.is_file():
                        continue

                    relative_path = file_path.relative_to(
                        media_directory
                    )

                    if any(
                        part.startswith(".")
                        for part in relative_path.parts
                    ):
                        continue

                    extension = file_path.suffix.lower()
                    media_type = self._get_media_type(extension)

                    if media_type is None:
                        continue

                    stat = file_path.stat()

                    entry = {
                        "name": file_path.stem,
                        "fileName": file_path.name,
                        "path": str(file_path),
                        "extension": extension.lstrip(".").upper(),
                        "type": media_type,
                        "size": self._format_size(stat.st_size),
                        "modified": stat.st_mtime
                    }

                    media_files.append(entry)

                    if media_type == "VIDEO":
                        videos.append(entry)

                    elif media_type == "MUSIC":
                        music.append(entry)

                    elif media_type == "IMAGE":
                        images.append(entry)

                except OSError as error:
                    failures.append(f"{file_path}: {error}")

        # Newest files appear first.
        media_files.sort(
            key=lambda item: item["modified"],
            reverse=True
        )

        videos.sort(
            key=lambda item: item["modified"],
            reverse=True
        )

        music.sort(
            key=lambda item: item["modified"],
            reverse=True
        )

        images.sort(
            key=lambda item: item["modified"],
            reverse=True
        )

        self._media_files = media_files
        self._videos = videos
        self._music = music
        self._images = images

        self.mediaChanged.emit()

        if failures:
            self.statusChanged.emit(
                f"Media library updated · {len(media_files)} files; "
                f"{len(failures)} path error(s): {failures[0]}"
            )
        else:
            self.statusChanged.emit(
                f"Media library updated · {len(media_files)} files"
            )

    @Slot(str)
    def open_file(self, file_path):
        path = Path(file_path)

        if not path.exists() or not path.is_file():
            self.statusChanged.emit(
                "Media file not found"
            )
            self.scan()
            return

        success = QDesktopServices.openUrl(
            QUrl.fromLocalFile(str(path))
        )

        if success:
            self.statusChanged.emit(
                f"Opening {path.name}"
            )
        else:
            self.statusChanged.emit(
                f"Could not open {path.name}"
            )

    @Slot()
    def open_folder(self):
        QDesktopServices.openUrl(
            QUrl.fromLocalFile(str(self._media_directories[0]))
        )
