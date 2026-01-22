#!/bin/bash
set -e

INSTALL_DIR="/opt/clicom"
USER_HOME=$(eval echo ~$SUDO_USER)
OS_TYPE=$(uname)

# Determine shell config files
if [ "$OS_TYPE" == "Darwin" ]; then
    BASHRC="$USER_HOME/.bash_profile"
    ZSHRC="$USER_HOME/.zshrc"
else
    BASHRC="$USER_HOME/.bashrc"
    ZSHRC="$USER_HOME/.zshrc"
fi

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash install.sh"
  exit 1
fi

echo "[*] Detecting System: $OS_TYPE"

# 1. Install Dependencies
echo "[*] Installing dependencies..."
if command -v dnf &> /dev/null; then
    dnf install -y python3 python3-pip git
elif command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y python3-venv python3-pip git
elif [ "$OS_TYPE" == "Darwin" ]; then
    # macOS handling
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew not found. Please install it first: https://brew.sh"
        exit 1
    fi
    # On macOS, we usually don't sudo brew. Run as SUDO_USER
    sudo -u "$SUDO_USER" brew install python git || true
else
    echo "Warning: Unknown system. Ensure python3 and git are installed."
fi

echo "[*] Setting up directories..."
mkdir -p "$INSTALL_DIR/src"
mkdir -p "$INSTALL_DIR/repo"
mkdir -p "$INSTALL_DIR/config"
chown -R "$SUDO_USER" "$INSTALL_DIR" # Ensure user can manage their repo/config

# Fix git safe directory
sudo -u "$SUDO_USER" git config --global --add safe.directory "$INSTALL_DIR/repo"

# API KEY SETUP
ENV_FILE="$INSTALL_DIR/config/.env"
if [ ! -f "$ENV_FILE" ]; then
    if [ -n "$GOOGLE_API_KEY" ]; then
        echo "GOOGLE_API_KEY=\"$GOOGLE_API_KEY\"" > "$ENV_FILE"
    else
        echo -e "\033[92m[?] Enter your Google API Key:\033[0m"
        read -r API_KEY
        if [ -n "$API_KEY" ]; then
            echo "GOOGLE_API_KEY=\"$API_KEY\"" > "$ENV_FILE"
        fi
    fi
fi
chmod 600 "$ENV_FILE"
chown "$SUDO_USER" "$ENV_FILE"

# Create default custom prompt
if [ ! -f "$INSTALL_DIR/config/custom_prompt.txt" ]; then
    echo "You are a professional Linux/macOS assistant." > "$INSTALL_DIR/config/custom_prompt.txt"
    chown "$SUDO_USER" "$INSTALL_DIR/config/custom_prompt.txt"
fi

# Copy repo
if [ "$(realpath .)" != "$(realpath "$INSTALL_DIR/repo")" ]; then
    cp -r . "$INSTALL_DIR/repo/"
    chown -R "$SUDO_USER" "$INSTALL_DIR/repo"
fi

# VENV Setup
if [ ! -d "$INSTALL_DIR/venv" ]; then
    sudo -u "$SUDO_USER" python3 -m venv "$INSTALL_DIR/venv"
fi

sudo -u "$SUDO_USER" "$INSTALL_DIR/venv/bin/pip" install --upgrade pip > /dev/null
sudo -u "$SUDO_USER" "$INSTALL_DIR/venv/bin/pip" install -r requirements.txt

# Copy source files
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
echo "Restart terminal or run: source $BASHRC (or $ZSHRC)"
