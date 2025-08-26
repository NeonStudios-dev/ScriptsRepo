#!/bin/sh

set -e  # Exit on error

# Check if dotnet is installed
if ! command -v dotnet >/dev/null 2>&1; then
    echo "⚠️  .NET SDK not found. Installing dotnet-sdk-8.0 via pacman..."
    sudo pacman -Sy --noconfirm dotnet-sdk-8.0
else
    echo "✅ .NET SDK already installed."
fi

# Create temp directory
TMP_DIR=$(mktemp -d)
echo "📂 Created temporary build directory: $TMP_DIR"

# Clone repo into temp directory
echo "📥 Cloning repository into temp dir..."
git clone https://github.com/neonstudios-dev/pux.git "$TMP_DIR/pux"

cd "$TMP_DIR/pux" || { echo "❌ Failed to enter project directory"; exit 1; }

# Add Newtonsoft.Json package before building
echo "📦 Adding Newtonsoft.Json (v13.0.4-beta1)..."
dotnet add package Newtonsoft.Json --version 13.0.4-beta1

# Build project
echo "⚙️ Building project in Release mode..."
dotnet publish -c Release -r linux-x64 --self-contained false

# Find publish directory dynamically
PUBLISH_DIR=$(find ./pux/bin/Release -type d -path "*/linux-x64/publish" | head -n 1)
BINARY="$PUBLISH_DIR/pux"

if [ ! -f "$BINARY" ]; then
  echo "❌ Build failed or binary not found!"
  exit 1
fi

echo "🔑 Making binary executable..."
chmod +x "$BINARY"

# Backup old binary if it exists
if [ -f "/usr/local/bin/pux" ]; then
    echo "♻️  Existing installation found. Backing up old binary..."
    sudo mv /usr/local/bin/pux /usr/local/bin/pux.bak
fi

# Install binary
echo "🚚 Moving binary to /usr/local/bin (requires sudo)..."
sudo mv "$BINARY" /usr/local/bin/pux

# Cleanup
echo "🧹 Cleaning up temporary files..."
cd ~
rm -rf "$TMP_DIR"

echo "✅ Installation complete! You can now run 'pux' from anywhere."
