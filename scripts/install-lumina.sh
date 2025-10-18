#!/bin/bash
# Installer for dotnet-build script - Downloads and installs

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${CYAN}>>> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Configuration
SCRIPT_NAME="lumina"
SCRIPT_URL="https://raw.githubusercontent.com/NeonStudios-dev/ScriptsRepo/refs/heads/main/scripts/build.sh"
INSTALL_DIR="/usr/local/bin"
TEMP_FILE="/tmp/lumina-temp"

echo ""
print_status "Dotnet Multi-Platform Build Script Installer"
echo ""

# Check for curl or wget
if command -v curl &> /dev/null; then
    DOWNLOADER="curl"
    print_status "Using curl for download"
elif command -v wget &> /dev/null; then
    DOWNLOADER="wget"
    print_status "Using wget for download"
else
    print_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

# Download the script
print_status "Downloading build script..."
if [ "$DOWNLOADER" = "curl" ]; then
    if curl -fsSL "$SCRIPT_URL" -o "$TEMP_FILE"; then
        print_success "Download complete"
    else
        print_error "Download failed. Please check the URL or your internet connection."
        exit 1
    fi
else
    if wget -q "$SCRIPT_URL" -O "$TEMP_FILE"; then
        print_success "Download complete"
    else
        print_error "Download failed. Please check the URL or your internet connection."
        exit 1
    fi
fi

# Verify the downloaded file is a bash script
if ! head -n 1 "$TEMP_FILE" | grep -q "^#!.*bash"; then
    print_error "Downloaded file doesn't appear to be a bash script"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Check if we need sudo
if [ -w "$INSTALL_DIR" ]; then
    SUDO=""
else
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
        print_warning "Administrator privileges required. You may be prompted for your password."
    else
        print_error "Cannot write to $INSTALL_DIR and sudo is not available"
        rm -f "$TEMP_FILE"
        exit 1
    fi
fi

# Install the script
print_status "Installing to $INSTALL_DIR/$SCRIPT_NAME..."
$SUDO mv "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"

# Make it executable
print_status "Setting permissions..."
$SUDO chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Verify installation
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ] && [ -x "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    print_success "Installation complete!"
    echo ""
    print_status "You can now run the build script from anywhere using:"
    echo -e "  ${GREEN}$SCRIPT_NAME${NC}"
    echo ""
    print_status "Examples:"
    echo "  $SCRIPT_NAME --help"
    echo "  $SCRIPT_NAME -p ./src/MyApp"
    echo "  $SCRIPT_NAME --parallel --trimmed"
    echo ""
    
    # Check if it's in PATH
    if ! command -v "$SCRIPT_NAME" &> /dev/null; then
        print_warning "$INSTALL_DIR might not be in your PATH"
        print_status "Add this to your ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
        echo ""
        print_status "Then reload your shell:"
        echo "  source ~/.bashrc"
    fi
else
    print_error "Installation failed!"
    exit 1
fi

# Cleanup
rm -f "$TEMP_FILE"
