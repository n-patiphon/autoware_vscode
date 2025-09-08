#!/bin/bash

# VCS Tool Installation Script for Debian/Ubuntu
# Installs vcstool for managing multiple version control repositories

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

# Function to show help
show_help() {
    echo "VCS Tool Installation Script"
    echo ""
    echo "Installs vcstool for managing multiple version control repositories."
    echo "This tool is essential for Autoware development workspace management."
    echo ""
    echo "USAGE:"
    echo "  $0        Install with confirmation prompts"
    echo "  $0 -y     Install with auto-yes to all questions"
    echo "  $0 --help Show this help information"
    echo ""
    echo "DOCUMENTATION:"
    echo "  https://github.com/dirk-thomas/vcstool"
    echo "  https://packagecloud.io/dirk-thomas/vcstool"
    echo ""
}

# Global variable for auto-answering questions
AUTO_YES=false

# Check for command line arguments
for arg in "$@"; do
    case $arg in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown argument: $arg"
            show_help
            exit 1
            ;;
    esac
done

# Function to ask yes/no questions
ask_question() {
    local question="$1"
    if [[ "$AUTO_YES" == true ]]; then
        print_status "$question [Auto-yes]"
        return 0
    fi
    
    while true; do
        read -p "$question (y/N): " -n 1 -r
        echo
        case $REPLY in
            [Yy]*) return 0 ;;
            [Nn]*|"") return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
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

print_status "Starting VCS Tool installation on Debian/Ubuntu..."

# Check if vcstool is already installed
if command -v vcs &> /dev/null; then
    print_warning "VCS Tool is already installed. Version: $(vcs --version 2>/dev/null || echo 'Unknown')"
    if ! ask_question "Do you want to reinstall?"; then
        print_status "Installation cancelled."
        exit 0
    fi
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_status "Installing curl (required for repository setup)..."
    sudo apt update
    sudo apt install -y curl
    print_success "Curl installed successfully"
fi

if ! ask_question "Do you want to proceed with VCS Tool installation?"; then
    print_status "Installation cancelled by user."
    exit 0
fi

# Add vcstool repository
print_status "Adding vcstool repository..."
if curl -s https://packagecloud.io/install/repositories/dirk-thomas/vcstool/script.deb.sh | sudo bash; then
    print_success "VCS Tool repository added successfully"
else
    print_error "Failed to add VCS Tool repository"
    exit 1
fi

# Update package index
print_status "Updating package index..."
sudo apt update

# Install vcstool
print_status "Installing python3-vcstool..."
sudo apt install -y python3-vcstool

# Verify installation
print_status "Verifying VCS Tool installation..."
if command -v vcs &> /dev/null; then
    VERSION=$(vcs --version 2>/dev/null || echo "Unknown version")
    print_success "VCS Tool successfully installed! Version: $VERSION"
    
    echo
    print_success "Installation complete!"
    echo -e "${BLUE}Usage:${NC}"
    echo "  vcs import src < autoware.repos    # Import repositories from .repos file"
    echo "  vcs pull src                       # Pull latest changes for all repos"
    echo "  vcs status src                     # Show status of all repositories"
    echo "  vcs diff src                       # Show diff for all repositories"
    echo "  vcs --help                         # Show help"
    echo
    echo -e "${BLUE}Common Autoware workflow:${NC}"
    echo "  mkdir ~/autoware && cd ~/autoware"
    echo "  git clone https://github.com/autowarefoundation/autoware.git"
    echo "  vcs import src < autoware/autoware.repos"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "  • Set up your workspace with: ./setup.sh"
    echo "  • Open workspace in VS Code for development"
    
else
    print_error "VCS Tool installation failed!"
    exit 1
fi