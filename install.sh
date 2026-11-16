#!/bin/bash
set -e

OS=$(uname -s)
NODE_EXE=""

# -------------------------
# Hardcoded Node.js version (v22 LTS)
# -------------------------
NODE_VERSION="22.23.3"

# -------------------------
# Check for global Node.js installation
# -------------------------
if command -v node &> /dev/null; then
    NODE_EXE="node"
    echo "[INFO] Node.js is already installed globally."
fi

# -------------------------
# Download and extract portable version if not found globally
# -------------------------
if [ -z "$NODE_EXE" ]; then
    if [ "$OS" != "Darwin" ] && [ "$OS" != "Linux" ]; then
        echo "[ERROR] Unsupported OS: $OS"
        exit 1
    fi

    if [ "$OS" == "Darwin" ]; then
        ARCH="darwin-x64"
    else
        ARCH="linux-x64"
    fi

    EXTRACTED_DIR="$HOME/.vscode/node-v${NODE_VERSION}-${ARCH}"
    PORTABLE_NODE="$EXTRACTED_DIR/bin/node"
    NODE_TARBALL="$HOME/.vscode/node-v${NODE_VERSION}-${ARCH}.tar.xz"
    DOWNLOAD_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${ARCH}.tar.xz"

    if [ -f "$PORTABLE_NODE" ]; then
        echo "[INFO] Portable Node.js v${NODE_VERSION} found."
        NODE_EXE="$PORTABLE_NODE"
        export PATH="$EXTRACTED_DIR/bin:$PATH"
    else
        echo "[INFO] Downloading Node.js v${NODE_VERSION}..."
        mkdir -p "$HOME/.vscode"

        if command -v curl &> /dev/null; then
            curl -fSL -o "$NODE_TARBALL" "$DOWNLOAD_URL"
        elif command -v wget &> /dev/null; then
            wget -q -O "$NODE_TARBALL" "$DOWNLOAD_URL"
        else
            echo "[ERROR] Neither curl nor wget is available."
            exit 1
        fi

        # SAFETY CHECK
        if ! tar -tf "$NODE_TARBALL" >/dev/null 2>&1; then
            echo "[ERROR] Downloaded file is not a valid archive. Download likely failed."
            rm -f "$NODE_TARBALL"
            exit 1
        fi

        echo "[INFO] Extracting Node.js..."
        tar -xf "$NODE_TARBALL" -C "$HOME/.vscode"
        rm -f "$NODE_TARBALL"

        if [ -f "$PORTABLE_NODE" ]; then
            echo "[INFO] Portable Node.js extracted successfully."
            NODE_EXE="$PORTABLE_NODE"
            export PATH="$EXTRACTED_DIR/bin:$PATH"
        else
            echo "[ERROR] node executable not found after extraction."
            exit 1
        fi
    fi
fi

# -------------------------
# Verify Node.js works
# -------------------------
if [ -z "$NODE_EXE" ]; then
    echo "[ERROR] Node.js executable not set."
    exit 1
fi

if ! "$NODE_EXE" -v > /dev/null 2>&1; then
    echo "[ERROR] Node.js execution failed."
    exit 1
fi

echo "[INFO] Using Node.js: $("$NODE_EXE" -v)"
echo "[INFO] Node is available at: $NODE_EXE"

# Note: If you are running this as a script, the PATH change will only apply 
# while this script is running. If you need it globally, you need to add:
# export PATH="$EXTRACTED_DIR/bin:$PATH" to your ~/.bashrc or ~/.zshrc file.