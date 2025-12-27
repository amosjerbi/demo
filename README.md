# Fetcher

A ROM downloading and management tool for retro gaming devices, with both a Python-based fetcher and a Pico-8 game showcase.

## Projects

### 🎮 ROM Fetcher
A comprehensive ROM downloading tool built for PortMaster-compatible devices.

**Features:**
- Multi-platform ROM downloading from various sources
- LÖVE2D-based user interface with on-screen keyboard
- Support for multiple gaming platforms (NES, SNES, Genesis, etc.)
- Automatic ROM organization and management
- Compatible with handheld gaming devices

**Components:**
- `fetcher.py` - Main ROM fetching engine with platform support
- `downloaderui/` - LÖVE2D-based graphical interface
- `fetcher.sh` - PortMaster launcher script
- `download.py` & `downloader.py` - Download management modules

### 🕹️ Pico-8 Game
A simple Pico-8 game created to showcase the Romnix app in a YouTube short.

**Location:** `pico-8/`
- `romnix.p8.png` - Pico-8 cartridge file
- `romnix.p8.png.zip` - Compressed cartridge

## Usage

### Running the ROM Fetcher
For PortMaster-compatible devices:
```bash
./fetcher.sh
```

The script will:
1. Set up the proper environment
2. Launch the LÖVE2D interface
3. Allow browsing and downloading ROMs from various sources

### Platform Support
The fetcher supports multiple retro gaming platforms including:
- NES/Famicom
- SNES/Super Famicom  
- Sega Genesis/Mega Drive
- Game Boy/Game Boy Color
- And many more...

## Requirements

- LÖVE2D engine (included in `libs/`)
- Python 3.x
- PortMaster-compatible device (or Linux system)
- Internet connection for ROM downloading

## License

Free to use for personal retro gaming purposes.
