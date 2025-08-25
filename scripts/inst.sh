#!/bin/sh

set -e  # Exit if any command fails

echo "📥 Cloning repository..."
git clone https://github.com/neonstudios-dev/pux.git

echo "📂 Entering project directory..."
cd pux || { echo "❌ Failed to enter pux directory"; exit 1; }

echo "⚙️ Building project in Release mode..."
dotnet publish -c Release -r linux-x64 --self-contained false

# Find the publish directory dynamically
PUBLISH_DIR=$(find ./bin/Release -type d -path "*/linux-x64/publish" | head -n 1)
BINARY="$PUBLISH_DIR/pux"

if [ ! -f "$BINARY" ]; then
  echo "❌ Build failed or binary not found!"
  exit 1
fi

echo "🔑 Making binary executable..."
chmod +x "$BINARY"

echo "🚚 Moving binary to /usr/local/bin (requires sudo)..."
sudo mv "$BINARY" /usr/local/bin/pux

echo "✅ Installation complete! You can now run 'pux' from anywhere."
