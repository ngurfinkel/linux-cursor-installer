#!/bin/bash

# Define colors and symbols
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
CHECK="✓"
CROSS="✗"

# Define common messages
MSG_SUDO_PROMPT="You may be prompted for your password to install system components."
MSG_PRESERVE_DATA="Note: The following directories containing your personal data will be preserved:"
MSG_COMPLETE_REMOVE="To completely remove Cursor, including your personal data, manually delete these directories."
MSG_LAUNCH_OPTIONS="You can launch Cursor AI IDE from your applications menu or by opening a new terminal and typing: cursor"
MSG_SOURCE_SHELL="Remember to open a new terminal or run 'source ~/.bashrc' (or 'source ~/.zshrc' if you use Zsh) to use the alias immediately."

# Simple logging function
log_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

log_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

log_info() {
    echo -e "${NC} $1"
}

# Define variables
CURSOR_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
ICON_URL="https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/dark/cursor.png"
APPIMAGE_PATH="/opt/cursor.appimage"
ICON_PATH="/opt/cursor.png"
DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"
ALIAS_FILE="/etc/profile.d/cursor.sh"
LAUNCHER_SCRIPT="/opt/cursor-launcher.sh"

# Define the alias command - using a launcher script
ALIAS_COMMAND="alias cursor=\"$LAUNCHER_SCRIPT\""

# Add these variables to define user data locations
USER_CONFIG_DIR="$HOME/.config/Cursor"
USER_DATA_DIR="$HOME/.cursor"

# Function to ensure sudo privileges for a command
run_with_sudo() {
    if ! sudo -v &>/dev/null; then
        echo "This operation requires sudo privileges."
        if ! sudo true; then
            echo "Failed to obtain sudo privileges. Exiting."
            exit 1
        fi
    fi
    sudo "$@"
}

# Function to ensure required packages are installed
ensure_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo "curl not found, installing curl..."
        run_with_sudo apt-get update && run_with_sudo apt-get install -y curl
    fi

    if ! dpkg -l | grep -q libfuse2; then
        echo "libfuse2 not found, installing libfuse2..."
        run_with_sudo apt-get update && run_with_sudo apt-get install -y libfuse2
    fi
}

# Function to install Cursor
install_cursor() {
    log_info "Starting installation of Cursor AI IDE..."
    log_info "$MSG_SUDO_PROMPT"
    
    # Ensure dependencies are installed
    ensure_dependencies

    # Get the download URL from the API
    log_info "Fetching download URL..."
    # MODIFIED LINE: Added -L to follow redirects
    DOWNLOAD_JSON=$(curl -sL "$CURSOR_URL")
    DOWNLOAD_URL=$(echo "$DOWNLOAD_JSON" | grep -o '"downloadUrl":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        log_error "Failed to extract download URL from API response."
        echo "API Response: $DOWNLOAD_JSON"
        exit 1
    fi
    
    log_info "Downloading Cursor AppImage from: $DOWNLOAD_URL"
    
    # Create temporary download location
    TEMP_DOWNLOAD="/tmp/cursor-appimage-$USER"
    if ! curl -L "$DOWNLOAD_URL" -o "$TEMP_DOWNLOAD"; then
        log_error "Failed to download Cursor AppImage."
        exit 1
    fi
    
    # Move to final location with sudo
    run_with_sudo mv "$TEMP_DOWNLOAD" "$APPIMAGE_PATH"
    
    # Set executable permission on the AppImage
    run_with_sudo chmod +x "$APPIMAGE_PATH"

    # Download the Cursor icon
    log_info "Downloading Cursor icon..."
    TEMP_ICON="/tmp/cursor-icon-$USER.png"
    if ! curl -L "$ICON_URL" -o "$TEMP_ICON"; then
        log_error "Failed to download the icon. Continuing installation without custom icon."
    else
        run_with_sudo mv "$TEMP_ICON" "$ICON_PATH"
    fi

    # Create a launcher script that properly detaches the process
    log_info "Creating launcher script..."
    TEMP_LAUNCHER="/tmp/cursor-launcher-$USER.sh"
    cat > "$TEMP_LAUNCHER" <<EOF
#!/bin/bash
# Launch Cursor in a way that ensures it continues running after terminal closes
# Pass all arguments to Cursor
nohup $APPIMAGE_PATH --no-sandbox "\$@" >/dev/null 2>&1 &
EOF
    chmod +x "$TEMP_LAUNCHER"
    run_with_sudo mv "$TEMP_LAUNCHER" "$LAUNCHER_SCRIPT"
    run_with_sudo chmod +x "$LAUNCHER_SCRIPT"

    # Create the desktop entry
    log_info "Creating desktop entry..."
    TEMP_DESKTOP="/tmp/cursor-$USER.desktop"
    cat > "$TEMP_DESKTOP" <<EOF
[Desktop Entry]
Name=Cursor AI IDE
Exec=$LAUNCHER_SCRIPT
Icon=$ICON_PATH
Type=Application
Categories=Development;
Terminal=false
StartupNotify=true
EOF
    run_with_sudo mv "$TEMP_DESKTOP" "$DESKTOP_ENTRY_PATH"

    # Create a system-wide alias
    log_info "Adding system-wide alias..."
    TEMP_ALIAS="/tmp/cursor-alias-$USER.sh"
    echo "#!/bin/bash" > "$TEMP_ALIAS"
    echo "$ALIAS_COMMAND" >> "$TEMP_ALIAS"
    run_with_sudo mv "$TEMP_ALIAS" "$ALIAS_FILE"
    run_with_sudo chmod +x "$ALIAS_FILE"

    # Add alias to user shell config files
    if [ -f "$HOME/.bashrc" ]; then
        log_info "Adding alias to $HOME/.bashrc..."
        if ! grep -qF "alias cursor=" "$HOME/.bashrc"; then
            echo "$ALIAS_COMMAND" >> "$HOME/.bashrc"
        fi
    fi

    # Handle .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        log_info "Adding alias to $HOME/.zshrc..."
        if ! grep -qF "alias cursor=" "$HOME/.zshrc"; then
            echo "$ALIAS_COMMAND" >> "$HOME/.zshrc"
        fi
    fi

    # Update the desktop database
    log_info "Updating desktop database..."
    if command -v update-desktop-database &> /dev/null; then
        run_with_sudo update-desktop-database /usr/share/applications
    else
        log_error "update-desktop-database command not found. Please update your desktop database manually."
    fi

    log_success "Installation complete!"
    log_info "$MSG_LAUNCH_OPTIONS"
    log_info "$MSG_SOURCE_SHELL"
}

# Function to uninstall Cursor
uninstall_cursor() {
    log_info "Starting uninstall of Cursor AI IDE..."
    log_info "$MSG_SUDO_PROMPT"
    log_info "$MSG_PRESERVE_DATA"
    echo "  - Configuration: $USER_CONFIG_DIR"
    echo "  - User data: $USER_DATA_DIR"
    echo ""

    # Remove the Cursor AppImage
    if [ -f "$APPIMAGE_PATH" ]; then
        log_info "Removing $APPIMAGE_PATH..."
        run_with_sudo rm "$APPIMAGE_PATH"
    else
        log_error "No AppImage found at $APPIMAGE_PATH."
    fi

    # Remove the launcher script
    if [ -f "$LAUNCHER_SCRIPT" ]; then
        log_info "Removing $LAUNCHER_SCRIPT..."
        run_with_sudo rm "$LAUNCHER_SCRIPT"
    else
        log_error "No launcher script found at $LAUNCHER_SCRIPT."
    fi

    # Remove the icon
    if [ -f "$ICON_PATH" ]; then
        log_info "Removing $ICON_PATH..."
        run_with_sudo rm "$ICON_PATH"
    else
        log_error "No icon file found at $ICON_PATH."
    fi

    # Remove the desktop entry
    if [ -f "$DESKTOP_ENTRY_PATH" ]; then
        log_info "Removing $DESKTOP_ENTRY_PATH..."
        run_with_sudo rm "$DESKTOP_ENTRY_PATH"
    else
        log_error "No desktop entry found at $DESKTOP_ENTRY_PATH."
    fi

    # Remove the alias file
    if [ -f "$ALIAS_FILE" ]; then
        log_info "Removing $ALIAS_FILE..."
        run_with_sudo rm "$ALIAS_FILE"
    else
        log_error "No alias file found at $ALIAS_FILE."
    fi

    # Remove alias from user shell config files
    if [ -f "$HOME/.bashrc" ]; then
        log_info "Removing alias from $HOME/.bashrc..."
        sed -i "\#alias cursor=\"$LAUNCHER_SCRIPT\"#d" "$HOME/.bashrc"
    fi

    # Remove from .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        log_info "Removing alias from $HOME/.zshrc..."
        sed -i "\#alias cursor=\"$LAUNCHER_SCRIPT\"#d" "$HOME/.zshrc"
    fi

    # Update the desktop database
    log_info "Updating desktop database..."
    if command -v update-desktop-database >/dev/null 2>&1; then
        run_with_sudo update-desktop-database /usr/share/applications
    else
        log_error "Command 'update-desktop-database' not found."
    fi

    log_success "Uninstallation complete. Your personal data and configurations have been preserved in:"
    echo "  $USER_CONFIG_DIR"
    echo "  $USER_DATA_DIR"
    log_info "$MSG_COMPLETE_REMOVE"
}

# Function to display usage
show_help() {
    log_info "Usage: $0 [option]"
    echo "Options:"
    echo "  install    - Install Cursor AI IDE"
    echo "  uninstall  - Uninstall Cursor AI IDE"
    echo "  update     - Reinstall Cursor AI IDE with latest version"
    echo "  help       - Show this help message"
}

# Main script logic
case "$1" in
    "install")
        install_cursor
        ;;
    "uninstall")
        uninstall_cursor
        ;;
    "update")
        log_info "Updating Cursor AI IDE to latest version..."
        uninstall_cursor
        install_cursor
        ;;
    "help"|"")
        show_help
        ;;
    *)
        log_error "Invalid option: $1"
        show_help
        exit 1
        ;;
esac

exit 0
