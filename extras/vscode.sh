#!/bin/bash

# VS Code Installation Script for Debian/Ubuntu
# Downloads and installs VS Code from official Microsoft repository

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. Run as a regular user with sudo privileges."
    exit 1
fi

# Check if apt is available
if ! command -v apt &> /dev/null; then
    print_error "This script only supports Debian/Ubuntu systems with apt package manager."
    exit 1
fi

print_status "Starting VS Code installation on Debian/Ubuntu..."

# Check if VS Code is already installed
if command -v code &> /dev/null; then
    print_warning "VS Code is already installed. Version: $(code --version | head -n1)"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled."
        exit 0
    fi
fi

# Update package index
print_status "Updating package index..."
sudo apt update

# Install dependencies
print_status "Installing dependencies..."
sudo apt install -y wget gpg software-properties-common apt-transport-https

# Download and install Microsoft GPG key
print_status "Adding Microsoft GPG key..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Update package index with new repository
print_status "Updating package index with VS Code repository..."
sudo apt update

# Install VS Code
print_status "Installing VS Code..."
sudo apt install -y code

# Clean up
rm -f packages.microsoft.gpg

# Verify installation
print_status "Verifying VS Code installation..."
if command -v code &> /dev/null; then
    VERSION=$(code --version | head -n1)
    print_success "VS Code successfully installed! Version: $VERSION"
    
    # Check if running in a desktop environment
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        print_status "Desktop environment detected."
        read -p "Would you like to launch VS Code now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Launching VS Code..."
            code &
        fi
    else
        print_status "No desktop environment detected. VS Code can be launched with 'code' command."
    fi
    
    echo
    print_success "Installation complete!"
    echo -e "${BLUE}Usage:${NC}"
    echo "  code                    # Launch VS Code"
    echo "  code <file>            # Open file in VS Code"
    echo "  code <folder>          # Open folder in VS Code"
    echo "  code --help            # Show help"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "  • Install extensions with: ./extras/extensions.sh"
    echo "  • Set up your workspace with: ./setup.sh"
    
else
    print_error "VS Code installation failed!"
    exit 1
fi
