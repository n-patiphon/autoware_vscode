#!/bin/bash

# VS Code Extensions Installation Script
# Based on autoware:universe-devel-cuda devcontainer configuration

set -e

echo "Installing VS Code extensions for Autoware development..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to install extension with error handling
install_extension() {
    local extension=$1
    local category=$2
    
    echo -e "${YELLOW}Installing $category extension: $extension${NC}"
    
    if code --install-extension "$extension" --force; then
        echo -e "${GREEN}✓ Successfully installed: $extension${NC}"
    else
        echo -e "${RED}✗ Failed to install: $extension${NC}"
        return 1
    fi
}

# Check if code command is available
if ! command -v code &> /dev/null; then
    echo -e "${RED}Error: 'code' command not found. Please ensure VS Code is installed and added to PATH.${NC}"
    exit 1
fi

echo -e "${GREEN}Starting extension installation...${NC}"
echo

# ROS 2 Extensions
echo -e "${YELLOW}=== Installing ROS 2 Extensions ===${NC}"
install_extension "Ranch-Hand-Robotics.rde-pack" "ROS 2"

# C++ Extensions
echo -e "${YELLOW}=== Installing C++ Extensions ===${NC}"
install_extension "cschlosser.doxdocgen" "C++ Documentation"
install_extension "llvm-vs-code-extensions.vscode-clangd" "C++ Language Server"
install_extension "ms-vscode.cpptools-extension-pack" "C++ Tools"
install_extension "nvidia.nsight-vscode-edition" "NVIDIA CUDA"

# CMake Extensions
echo -e "${YELLOW}=== Installing CMake Extensions ===${NC}"
install_extension "twxs.cmake" "CMake"

# Shell Script Extensions
echo -e "${YELLOW}=== Installing Shell Script Extensions ===${NC}"
install_extension "timonwong.shellcheck" "Shell Linting"
install_extension "foxundermoon.shell-format" "Shell Formatting"

# Python Extensions
echo -e "${YELLOW}=== Installing Python Extensions ===${NC}"
install_extension "ms-python.autopep8" "Python Formatting"
install_extension "ms-python.debugpy" "Python Debugging"
install_extension "ms-python.python" "Python"
install_extension "ms-python.vscode-pylance" "Python Language Server"

# Git Extensions
echo -e "${YELLOW}=== Installing Git Extensions ===${NC}"
install_extension "eamodio.gitlens" "Git Lens"
install_extension "github.vscode-pull-request-github" "GitHub PR"

# Remote Development Extensions
echo -e "${YELLOW}=== Installing Remote Development Extensions ===${NC}"
install_extension "ms-azuretools.vscode-docker" "Docker"
install_extension "ms-vscode.remote-explorer" "Remote Explorer"
install_extension "ms-vscode-remote.vscode-remote-extensionpack" "Remote Development Pack"

# Extra Tools
echo -e "${YELLOW}=== Installing Extra Tools ===${NC}"
install_extension "redhat.vscode-xml" "XML Support"
install_extension "redhat.vscode-yaml" "YAML Support"
install_extension "streetsidesoftware.code-spell-checker" "Spell Checker"
install_extension "yzhang.markdown-all-in-one" "Markdown Tools"

echo
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo -e "${GREEN}All extensions have been installed successfully!${NC}"
echo
echo "To verify installations, run: code --list-extensions"
echo "Restart VS Code to ensure all extensions are properly loaded."
