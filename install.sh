#!/bin/bash
set -e

INSTALL_DIR="/opt/clicom"
USER_HOME=$(eval echo ~$SUDO_USER)
BASHRC="$USER_HOME/.bashrc"
ZSHRC="$USER_HOME/.zshrc"

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash install.sh"
  exit 1
fi

echo "[*] Installing dependencies..."
if command -v dnf &> /dev/null; then
    dnf install -y python3 python3-pip git
elif command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y python3-venv python3-pip git
fi

echo "[*] Setting up directories..."
mkdir -p "$INSTALL_DIR/src"
mkdir -p "$INSTALL_DIR/repo"
mkdir -p "$INSTALL_DIR/config"

# Fix git safe directory
git config --global --add safe.directory "$INSTALL_DIR/repo"

# API KEY SETUP via .env file
ENV_FILE="$INSTALL_DIR/config/.env"
if [ ! -f "$ENV_FILE" ]; then
    if [ -n "$GOOGLE_API_KEY" ]; then
        echo "GOOGLE_API_KEY=\"$GOOGLE_API_KEY\"" > "$ENV_FILE"
    else
        echo -e "\033[92m[?] Enter your Google API Key:\033[0m"
        read -r API_KEY
        if [ -n "$API_KEY" ]; then
            echo "GOOGLE_API_KEY=\"$API_KEY\"" > "$ENV_FILE"
            echo "[*] API Key saved to $ENV_FILE"
        fi
    fi
fi
chmod 600 "$ENV_FILE" # Protect secrets

# Create default custom prompt
if [ ! -f "$INSTALL_DIR/config/custom_prompt.txt" ]; then
    echo "You are a professional Linux assistant." > "$INSTALL_DIR/config/custom_prompt.txt"
fi

# Copy repo (skip if already in repo)
if [ "$(realpath .)" != "$(realpath "$INSTALL_DIR/repo")" ]; then
    cp -r . "$INSTALL_DIR/repo/"
fi

if [ ! -d "$INSTALL_DIR/venv" ]; then
    python3 -m venv "$INSTALL_DIR/venv"
fi

"$INSTALL_DIR/venv/bin/pip" install --upgrade pip > /dev/null
"$INSTALL_DIR/venv/bin/pip" install -r requirements.txt

cp src/main.py src/recorder.py src/wrapper.sh "$INSTALL_DIR/src/"
cp uninstall.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/src/main.py"
chmod +x "$INSTALL_DIR/src/recorder.py"
chmod +x "$INSTALL_DIR/uninstall.sh"

SOURCE_LINE="source $INSTALL_DIR/src/wrapper.sh"

setup_rc() {
    local rc_file=$1
    if [ -f "$rc_file" ] && ! grep -Fxq "$SOURCE_LINE" "$rc_file"; then
        echo -e "\n# Clicom AI Tool\n$SOURCE_LINE" >> "$rc_file"
        echo "[*] Added to $rc_file"
    fi
}

setup_rc "$BASHRC"
setup_rc "$ZSHRC"

echo "=== Installation Successful ==="
echo "Restart terminal or run: source ~/.bashrc"