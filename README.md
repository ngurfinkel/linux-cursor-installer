# Linux Cursor Installer

A simple and reliable tool to install, update, and uninstall the Cursor AI IDE on Linux systems.

## Features

- Easy installation of Cursor AI IDE from official sources
- Desktop integration with application menu entry
- Command-line alias for quick access
- Clean uninstallation while preserving user data
- Update functionality to get the latest version
- Proper process handling for GUI applications

## Requirements

- Linux system with bash shell
- curl (will be installed automatically if missing)
- libfuse2 (will be installed automatically if missing)
- sudo privileges for system-wide installation

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/ngurfinkel/linux-cursor-installer/main/install.sh | bash -s install
```

### Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/ngurfinkel/linux-cursor-installer.git
cd linux-cursor-installer
```

2. Run the installer:
```bash
./install.sh install
```

## Usage

The installer supports several commands:

```bash
./install.sh [command]
```

### Available Commands

- `install` - Install Cursor AI IDE
- `uninstall` - Remove Cursor AI IDE (preserves user data)
- `update` - Update to the latest version
- `help` - Show usage information

### Examples

Install Cursor:
```bash
./install.sh install
```

Update to latest version:
```bash
./install.sh update
```

Remove Cursor:
```bash
./install.sh uninstall
```

## What Gets Installed

The installer will:

1. Download the latest Cursor AppImage to `/opt/cursor.appimage`
2. Create a launcher script at `/opt/cursor-launcher.sh`
3. Download the Cursor icon to `/opt/cursor.png`
4. Create a desktop entry at `/usr/share/applications/cursor.desktop`
5. Add a system-wide alias in `/etc/profile.d/cursor.sh`
6. Add the alias to your `~/.bashrc` and/or `~/.zshrc`

After installation, you can:
- Launch Cursor from your applications menu
- Run `cursor` command in terminal
- Open files with Cursor using `cursor filename`

## User Data Preservation

The uninstaller preserves your personal data in these directories:
- Configuration: `~/.config/Cursor`
- User data: `~/.cursor`

To completely remove all Cursor data, manually delete these directories after uninstalling.

## Troubleshooting

### Permission Issues
Make sure you have sudo privileges. The installer will prompt for your password when needed.

### Dependencies
If curl or libfuse2 are missing, the installer will attempt to install them automatically using apt-get.

### Desktop Integration
If the desktop entry doesn't appear immediately, try logging out and back in, or run:
```bash
sudo update-desktop-database /usr/share/applications
```

## Acknowledgments

- Cursor AI for providing the excellent IDE
- The Linux community for best practices in application installation
