# Fetcher

A file downloading and management tool for retro gaming devices that run Rocknix system.

## Projects

### 🎮 File Fetcher
A comprehensive file downloading tool built for PortMaster-compatible devices.

**Features:**
- Multi-platform file downloading from various sources
- LÖVE2D-based user interface with on-screen keyboard
- Support for multiple gaming platforms (NES, SNES, Genesis, etc.)
- Automatic file organization and management
- Compatible with handheld gaming devices

**Components:**
- `fetcher.py` - Main file fetching engine with platform support
- `downloaderui/` - LÖVE2D-based graphical interface
- `fetcher.sh` - PortMaster launcher script
- `download.py` & `downloader.py` - Download management modules

## How to Use

### First things first
1. Edit fetcher.py with your own links in line 14
2. Make sure to add your links in PLATFORM_URLS = {}
3. If a directory doesn't exist it'll be created

### Installation
1. Copy the entire `fetcher` directory to your device's ports folder (usually `/roms/ports/`)
2. Copy `fetcher.sh` to the same location
3. Run Fetcher from ports menu

## Requirements

- LÖVE2D engine (included in `libs/`)
- Python 3.x
- PortMaster-compatible device (or Linux system)
- Internet connection for file downloading


### Pico-8 Game
A simple Pico-8 game created to showcase Fetcher.

**Location:** `pico-8/`
- `romnix.p8.png` - Pico-8 cartridge file
- `romnix.p8.png.zip` - Compressed cartridge


## License

Free to use for personal retro gaming purposes.
