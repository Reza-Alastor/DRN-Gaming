# DRN Gaming

**A Linux gaming environment and launcher focused on PC gaming, retro gaming, and emulation.**

DRN Gaming is an open-source project designed to bring different gaming-related tools and experiences together in one desktop application.

The project aims to provide a unified interface for managing games, accessing retro gaming tools, browsing media, and interacting with useful system utilities.

> **Project status:** Early development. Features and interfaces are subject to change.

## Features

DRN Gaming is organized into four main sections:

### Games
- Game library management.
- Game launching and application discovery.
- Steam integration and library discovery.

### Retro
- RetroArch integration.
- Retro gaming library management.
- Configurable ROM directories and emulator settings.

### Media
- Media library access.
- Media file discovery and launching.

### System
- Access to common desktop utilities.
- Application launching.
- Basic system and session actions.

Feature availability may depend on the applications installed on your Linux system.

## Screenshots

Screenshots will be added here as the interface develops.

## Requirements

- Linux
- Python 3
- PySide6 6.12.0
- Qt Quick
- Qt Quick Controls

Some features require external applications, such as Steam, RetroArch, or KDE desktop utilities.

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/DRN-Gaming.git
cd DRN-Gaming
```

### 2. Create a virtual environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install dependencies

```bash
python -m pip install -r requirements.txt
```

### 4. Run DRN Gaming

```bash
python main.py
```

## Configuration and Data

DRN Gaming uses user-specific directories following the XDG Base Directory conventions.

Default locations:

| Purpose | Location |
|---|---|
| Configuration | `~/.config/drn-gaming/` |
| Application data | `~/.local/share/drn-gaming/` |
| Cache | `~/.cache/drn-gaming/` |
| State | `~/.local/state/drn-gaming/` |

The configuration file is:

```text
~/.config/drn-gaming/config.json
```

Users can configure application paths, game libraries, ROM directories, and media directories.

Existing project data may be migrated to the user's application data directory when the application initializes.

## ROMs

The repository includes an empty `ROMs/` directory as a reference location.

ROM files are intentionally excluded from version control. The default application-managed ROM directory is located under:

```text
~/.local/share/drn-gaming/ROMs/
```

Users can configure additional ROM directories.

**No copyrighted game ROMs are distributed with this project.** Users are responsible for ensuring that their use of game files complies with applicable laws.

## Project Structure

```text
DRN-Gaming/
├── config/
│   └── defaults.json
├── data/
│   ├── games.json
│   └── retro_library.json
├── qml/
│   └── main.qml
├── ROMs/
│   └── .gitkeep
├── tests/
│   └── test_portable_paths.py
├── main.py
├── path_manager.py
├── game_manager.py
├── media_manager.py
├── retroarch_manager.py
├── system_manager.py
├── requirements.txt
├── LICENSE
└── README.md
```

## Running Tests

The project currently includes tests for portable paths and configuration behavior.

Run them with:

```bash
python -m unittest discover -s tests -v
```

## Contributing

Contributions, suggestions, bug reports, and improvements are welcome.

Before submitting changes, please:

1. Check that the application runs correctly.
2. Run the available tests.
3. Avoid committing personal configuration files, ROMs, or private data.
4. Keep changes focused and document significant behavior changes.

A dedicated contribution guide may be added as the project grows.

## License

DRN Gaming is licensed under the [MIT License](LICENSE).

You are free to use, modify, and distribute this project under the terms of that license.

---

**DRN Gaming**

Part of the DRN project ecosystem.