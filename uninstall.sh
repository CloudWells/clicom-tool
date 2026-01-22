#!/bin/bash

INSTALL_DIR="/opt/clicom"
USER_HOME=$(eval echo ~$SUDO_USER)
BASHRC="$USER_HOME/.bashrc"

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo ./uninstall.sh"
  exit 1
fi

echo "[*] Removing $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"

echo "[*] Cleaning up $BASHRC..."
if [ -f "$BASHRC" ]; then
    # Remove the source line and the comment
    sed -i '/# Clicom AI Tool/d' "$BASHRC"
    sed -i '/source \/opt\/clicom\/src\/wrapper.sh/d' "$BASHRC"
fi

echo "=== Clicom uninstalled successfully ==="
echo "Please restart your terminal."
