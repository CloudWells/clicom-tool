#!/bin/bash

function clicom() {
    local INSTALL_DIR="/opt/clicom"
    local PYTHON="$INSTALL_DIR/venv/bin/python3"
    local YOLO_FILE="/tmp/clicom_yolo_$USER"
    local MODEL_FILE="/tmp/clicom_model_$USER"
    local PROMPT_FILE="$INSTALL_DIR/config/custom_prompt.txt"
    
    # Default model
    local CURRENT_MODEL="gemini-3-flash-preview"
    if [ -f "$MODEL_FILE" ]; then
        CURRENT_MODEL=$(cat "$MODEL_FILE")
    fi

    # 1. HELP
    if [[ "$*" == *"-help"* ]]; then
        echo -e "\033[92mClicom AI Tool — Usage Guide\033[0m"
        echo -e ""
        echo -e "Current Model: \033[93m$CURRENT_MODEL\033[0m"
        echo -e ""
        echo -e "\033[92mUsage:\033[0m clicom [options] [query]"
        echo -e ""
        echo -e "\033[92mOptions:\033[0m"
        echo -e "  \033[92m-ai\033[0m           Analyst mode: Run command + get AI opinion"
        echo -e "  \033[92m-fix\033[0m          Analyze logs and history to suggest a fix"
        echo -e "  \033[92m-wtf\033[0m          Explain the last terminal error or state"
        echo -e "  \033[92m-prompt\033[0m       Edit global AI instructions (persona)"
        echo -e "  \033[92m-h, --history\033[0m  Include recent command history context"
        echo -e "  \033[92m-log on/off\033[0m   Toggle session recording"
        echo -e "  \033[92m-yolo on/off\033[0m  Toggle no-confirmation mode"
        echo -e "  \033[92m-model [name]\033[0m Switch AI model (flash/pro/preview)"
        echo -e "  \033[92m-update\033[0m       Pull latest version from GitHub"
        echo -e "  \033[92m-help\033[0m         Show this guide"
        return
    fi

    # 2. LOGGING
    if [[ "$1" == "-log" && "$2" == "on" ]]; then
        "$PYTHON" "$INSTALL_DIR/src/recorder.py"
        return
    fi

    # 3. YOLO
    if [[ "$1" == "-yolo" ]]; then
        if [[ "$2" == "on" ]]; then
            touch "$YOLO_FILE"
            echo -e "\033[91mYOLO MODE ACTIVATED!\033[0m"
        else
            rm -f "$YOLO_FILE"
            echo "YOLO mode deactivated."
        fi
        return
    fi

    # 4. PROMPT EDITING
    if [[ "$1" == "-prompt" ]]; then
        local editor=${EDITOR:-nano}
        sudo $editor "$PROMPT_FILE"
        return
    fi

    # 5. MODEL SELECTION
    if [[ "$1" == "-model" ]]; then
        if [ -n "$2" ]; then
            echo "$2" > "$MODEL_FILE"
            echo -e "Model switched to: \033[93m$2\033[0m"
        else
            echo "Current model: $CURRENT_MODEL"
        fi
        return
    fi

    # 6. UPDATE
    if [[ "$1" == "-update" ]]; then
        echo "[*] Updating Clicom..."
        local OLD_PWD=$(pwd)
        sudo git config --global --add safe.directory "$INSTALL_DIR/repo"
        cd "$INSTALL_DIR/repo" || { echo "Update error: repo not found."; return 1; }
        sudo git pull origin main
        sudo ./install.sh
        cd "$OLD_PWD"
        echo "Update complete. Please restart terminal."
        return
    fi

    # 7. COMMAND GENERATION
    local cmd
    local history_context=""
    local is_ai_mode=false
    
    if [[ "$1" == "-ai" ]]; then
        is_ai_mode=true
        shift
    fi

    # History context
    if [[ "$*" == *"-h"* ]] || [[ "$*" == *"-fix"* ]] || [[ "$*" == *"-wtf"* ]]; then
        history_context=$(history | tail -n 20 | sed 's/^[ 0-9]*//')
    fi

    # Special handling for -wtf
    if [[ "$*" == *"-wtf"* ]]; then
        if [ -n "$history_context" ]; then
            echo "$history_context" | "$PYTHON" "$INSTALL_DIR/src/main.py" "-model" "$CURRENT_MODEL" "$@"
        else
            "$PYTHON" "$INSTALL_DIR/src/main.py" "-model" "$CURRENT_MODEL" "$@"
        fi
        return 0
    fi

    # Normal command generation
    if [ -n "$history_context" ]; then
        cmd=$(echo "$history_context" | "$PYTHON" "$INSTALL_DIR/src/main.py" "-model" "$CURRENT_MODEL" "$@")
    else
        cmd=$("$PYTHON" "$INSTALL_DIR/src/main.py" "-model" "$CURRENT_MODEL" "$@")
    fi
    
    local exit_code=$?
    if [ $exit_code -ne 0 ] || [ -z "$cmd" ]; then return $exit_code; fi

    echo -e "\033[92m> $cmd\033[0m"
    
    local execute=false
    if [ -f "$YOLO_FILE" ]; then
        execute=true
    else
        read -n 1 -r -p "Execute? (y/n): " key
        echo 
        if [[ "$key" =~ ^[yYдДlLгГнН]$ ]]; then
            execute=true
        fi
    fi

    if [ "$execute" = true ]; then
        if [ "$is_ai_mode" = true ]; then
            local output
            output=$(eval "$cmd" 2>&1)
            echo -e "$output"
            echo -e "\033[90m--- AI Analysis ---\033[0m"
            "$PYTHON" "$INSTALL_DIR/src/main.py" "-model" "$CURRENT_MODEL" "-opinion" "$output" "$@"
        else
            eval "$cmd"
        fi
        history -s "$cmd"
    else
        echo "Aborted."
    fi
}
