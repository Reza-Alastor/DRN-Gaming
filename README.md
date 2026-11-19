# DRN Gaming

**A customizable Linux gaming environment for PC gaming, retro gaming, and emulation.**

[English](#english) | [فارسی](#فارسی)

---

<a id="english"></a>

# 🇬🇧 English

## About

**DRN Gaming** is an open-source Linux gaming environment and launcher designed to bring different gaming-related tools and experiences together in one desktop application.

The project aims to provide a unified interface for managing game libraries, launching games, accessing retro gaming tools, browsing media, and interacting with useful system utilities.

DRN Gaming is part of the **DRN project ecosystem**.

> **Project status:** Early development. Features, interfaces, and architecture may change as the project evolves.

## Features

DRN Gaming is organized into four main sections:

### 🎮 Games

- Game library management.
- Game launching and application discovery.
- Steam integration and library discovery.

### 🕹️ Retro

- RetroArch integration.
- Retro gaming library management.
- Configurable ROM directories.
- Emulator and core settings.

### 🎬 Media

- Media library access.
- Media file discovery and launching.

### ⚙️ System

- Access to common desktop utilities.
- Application launching.
- Basic system and session actions.

Feature availability may depend on the applications and desktop environment installed on your Linux system.

## Requirements

- Linux
- Python 3
- PySide6 6.12.0
- Qt Quick
- Qt Quick Controls

Some features may require additional applications, such as:

- Steam
- RetroArch
- KDE desktop utilities

These applications are not bundled with DRN Gaming.

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/Reza-Alastor/DRN-Gaming.git
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

DRN Gaming uses user-specific directories following the **XDG Base Directory** conventions.

Default locations:

| Purpose | Location |
|---|---|
| Configuration | `~/.config/drn-gaming/` |
| Application data | `~/.local/share/drn-gaming/` |
| Cache | `~/.cache/drn-gaming/` |
| State | `~/.local/state/drn-gaming/` |

The main configuration file is:

```text
~/.config/drn-gaming/config.json
```

Users can configure application paths, game libraries, ROM directories, and media directories.

Existing project data may be migrated to the user's application data directory when the application initializes. Existing user data is preserved when a destination already exists.

## ROMs

The repository contains an empty `ROMs/` directory as a reference location.

The default application-managed ROM directory is:

```text
~/.local/share/drn-gaming/ROMs/
```

Additional ROM directories can be configured by the user.

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

Run the test suite with:

```bash
python -m unittest discover -s tests -v
```

## Contributing

Contributions, suggestions, bug reports, and improvements are welcome.

Before submitting changes:

1. Check that the application runs correctly.
2. Run the available tests.
3. Avoid committing personal configuration files, ROMs, or private data.
4. Keep changes focused and document significant behavior changes.

You can use the GitHub Issues section to report bugs or suggest improvements.

## License

DRN Gaming is licensed under the **MIT License**.

See the [LICENSE](LICENSE) file for details.

---

<a id="فارسی"></a>

# 🇮🇷 فارسی

## درباره پروژه

**DRN Gaming** یک محیط و لانچر متن‌باز برای سیستم‌عامل لینوکس است که با هدف یکپارچه‌سازی ابزارها و تجربه‌های مختلف مرتبط با بازی در یک برنامهٔ دسکتاپ توسعه داده می‌شود.

هدف پروژه فراهم‌کردن یک رابط یکپارچه برای مدیریت کتابخانهٔ بازی‌ها، اجرای بازی‌ها، دسترسی به ابزارهای بازی‌های رترو، مرور فایل‌های رسانه‌ای و استفاده از ابزارهای کاربردی سیستم است.

DRN Gaming بخشی از اکوسیستم پروژهٔ **DRN** محسوب می‌شود.

> **وضعیت پروژه:** در مراحل اولیهٔ توسعه قرار دارد. امکانات، رابط کاربری و معماری پروژه ممکن است در ادامه تغییر کنند.

## امکانات

DRN Gaming از چهار بخش اصلی تشکیل شده است:

### 🎮 Games — بازی‌ها

- مدیریت کتابخانهٔ بازی‌ها.
- اجرای بازی‌ها و شناسایی برنامه‌های مرتبط.
- یکپارچگی با Steam و شناسایی کتابخانه‌های آن.

### 🕹️ Retro — بازی‌های رترو

- یکپارچگی با RetroArch.
- مدیریت کتابخانهٔ بازی‌های رترو.
- امکان تنظیم مسیر پوشه‌های ROM.
- تنظیمات شبیه‌ساز و Coreها.

### 🎬 Media — رسانه

- دسترسی به کتابخانهٔ رسانه‌ای.
- شناسایی و اجرای فایل‌های رسانه‌ای.

### ⚙️ System — سیستم

- دسترسی به ابزارهای کاربردی دسکتاپ.
- اجرای برنامه‌ها.
- دسترسی به برخی عملیات پایهٔ سیستم و نشست کاربری.

در دسترس بودن بعضی امکانات به برنامه‌های نصب‌شده و محیط دسکتاپ لینوکس شما بستگی دارد.

## پیش‌نیازها

- سیستم‌عامل لینوکس
- Python 3
- PySide6 نسخهٔ 6.12.0
- Qt Quick
- Qt Quick Controls

بعضی قابلیت‌ها ممکن است به برنامه‌های جانبی مانند موارد زیر نیاز داشته باشند:

- Steam
- RetroArch
- ابزارهای محیط دسکتاپ KDE

این برنامه‌ها به‌صورت پیش‌فرض همراه DRN Gaming نصب نمی‌شوند.

## نصب و راه‌اندازی

### ۱. دریافت مخزن پروژه

```bash
git clone https://github.com/Reza-Alastor/DRN-Gaming.git
cd DRN-Gaming
```

### ۲. ساخت محیط مجازی Python

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### ۳. نصب وابستگی‌ها

```bash
python -m pip install -r requirements.txt
```

### ۴. اجرای DRN Gaming

```bash
python main.py
```

## تنظیمات و مسیرهای ذخیره‌سازی

DRN Gaming برای مدیریت اطلاعات کاربر از استاندارد **XDG Base Directory** استفاده می‌کند.

مسیرهای پیش‌فرض:

| کاربرد | مسیر |
|---|---|
| تنظیمات | `~/.config/drn-gaming/` |
| اطلاعات برنامه | `~/.local/share/drn-gaming/` |
| حافظهٔ موقت | `~/.cache/drn-gaming/` |
| اطلاعات وضعیت برنامه | `~/.local/state/drn-gaming/` |

فایل اصلی تنظیمات:

```text
~/.config/drn-gaming/config.json
```

کاربر می‌تواند مسیر برنامه‌های اجرایی، کتابخانه‌های بازی، پوشه‌های ROM و پوشه‌های رسانه‌ای را تنظیم کند.

هنگام راه‌اندازی برنامه، اطلاعات موجود در ساختار قدیمی پروژه ممکن است به مسیر اختصاصی اطلاعات کاربر منتقل شوند. اگر مقصد از قبل اطلاعاتی داشته باشد، اطلاعات موجود آن جایگزین نمی‌شوند.

## فایل‌های ROM

مخزن پروژه شامل یک پوشهٔ خالی به نام `ROMs/` است که صرفاً به‌عنوان مسیر مرجع در ساختار پروژه قرار گرفته است.

مسیر پیش‌فرض مدیریت ROMها توسط برنامه:

```text
~/.local/share/drn-gaming/ROMs/
```

کاربر می‌تواند مسیرهای دیگری نیز برای پوشه‌های ROM تنظیم کند.

**هیچ فایل ROM دارای حق نشر همراه این پروژه توزیع نمی‌شود.** مسئولیت رعایت قوانین مربوط به استفاده از فایل‌های بازی بر عهدهٔ کاربران است.

## ساختار پروژه

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

## اجرای تست‌ها

در حال حاضر پروژه شامل تست‌هایی برای بررسی مسیرهای قابل‌حمل و رفتار تنظیمات است.

برای اجرای تست‌ها از دستور زیر استفاده کنید:

```bash
python -m unittest discover -s tests -v
```

## مشارکت در پروژه

از مشارکت، پیشنهادها، گزارش خطاها و بهبودهای فنی استقبال می‌کنیم.

پیش از ارسال تغییرات:

1. از اجرای صحیح برنامه اطمینان حاصل کنید.
2. تست‌های موجود را اجرا کنید.
3. فایل‌های تنظیمات شخصی، ROMها و اطلاعات خصوصی را وارد مخزن نکنید.
4. تغییرات را تا حد امکان محدود و مشخص نگه دارید و تغییرات مهم در رفتار برنامه را مستند کنید.

برای گزارش مشکلات یا پیشنهاد قابلیت‌های جدید می‌توانید از بخش Issues مخزن GitHub استفاده کنید.

## مجوز

پروژهٔ DRN Gaming تحت مجوز **MIT License** منتشر شده است.

برای مشاهدهٔ جزئیات، فایل [LICENSE](LICENSE) را مطالعه کنید.

---

**DRN Gaming**

بخشی از اکوسیستم پروژهٔ DRN.

[مشاهده مخزن در GitHub](https://github.com/Reza-Alastor/DRN-Gaming)