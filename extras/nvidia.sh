#!/bin/bash

# NVIDIA Driver Installation Script
# This script installs the latest recommended NVIDIA driver from the graphics-drivers PPA.
#
# Usage:
#   ./nvidia.sh        - Install with prompts
#   ./nvidia.sh -y     - Install with auto-yes to all questions
#   ./nvidia.sh --help - Show help information

# --- Boilerplate and Helper Functions (from your style guide) ---

# Function to show help
show_help() {
    echo "NVIDIA Driver Installation Script"
    echo ""
    echo "Installs the latest stable NVIDIA driver for your specific hardware"
    echo "by using the official 'graphics-drivers/ppa' repository."
    echo ""
    echo "USAGE:"
    echo "  $0        Install with confirmation prompts"
    echo "  $0 -y     Install with auto-yes to all questions"
    echo "  $0 --help Show this help information"
    echo ""
    echo "IMPORTANT:"
    echo " - A reboot is REQUIRED to complete the installation."
    echo " - This script is designed for Ubuntu and Debian-based systems."
    echo ""
}

set -e

# Global variable for auto-answering questions
AUTO_YES=false

# Check for command line arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
elif [[ "$1" == "-y" ]]; then
    AUTO_YES=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
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

# Function to ask yes/no questions
ask_question() {
    local question="$1"
    local response
    
    if [[ "$AUTO_YES" == true ]]; then
        echo -e "\n${YELLOW}$question${NC}"
        echo -e "${GREEN}[AUTO: YES]${NC}"
        return 0
    fi
    
    echo -e "\n${YELLOW}$question${NC}"
    echo -e "${BLUE}[Y/n] (default: yes):${NC} \c"
    read -r response
    response=${response:-y}
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# --- Prerequisite Checks ---

check_system() {
    print_info "Checking system compatibility..."
    
    if [[ "$(uname)" != "Linux" ]]; then
        print_error "This script only supports Linux systems."
        exit 1
    fi
    
    if ! command -v lsb_release &> /dev/null; then
         print_error "'lsb_release' command not found. Cannot determine distribution."
         exit 1
    fi

    local distro
    distro=$(lsb_release -is)
    if [[ "$distro" != "Ubuntu" ]] && [[ "$distro" != "Debian" ]] && [[ "$distro" != "Linuxmint" ]]; then
        print_warning "This script is optimized for Ubuntu/Debian. Your system: $distro"
        if ! ask_question "Do you want to continue anyway?"; then
            print_info "Installation cancelled."
            exit 0
        fi
    fi
    print_success "System check passed."
}

check_secure_boot() {
    print_info "Checking for Secure Boot status..."
    if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
        print_warning "Secure Boot is enabled on your system."
        print_info "You will need to enroll a new MOK (Machine Owner Key) during the reboot process."
        print_info "A blue screen will appear after you restart. Follow these steps:"
        print_info "1. Select 'Enroll MOK'."
        print_info "2. Continue, then confirm enrollment."
        print_info "3. You will be prompted for the password you set during installation."
        if ! ask_question "Do you understand the Secure Boot steps and wish to continue?"; then
            print_info "Installation cancelled. Disable Secure Boot in your UEFI/BIOS settings if you prefer."
            exit 0
        fi
    else
        print_success "Secure Boot is disabled."
    fi
}


check_existing_driver() {
    if command -v nvidia-smi &> /dev/null; then
        print_warning "An existing NVIDIA driver is already installed."
        nvidia-smi --query-gpu=driver_version --format=csv,noheader
        if ! ask_question "Do you want to purge the old driver and install the latest recommended one?"; then
            print_info "Installation cancelled."
            exit 0
        fi
        return 0 # Indicates purge is needed
    fi
    return 1 # Indicates no purge needed
}

# --- Main Script ---

print_info "=== NVIDIA Driver Installation Script ==="
print_info "This script will install the latest stable driver for your GPU."
print_warning "A system reboot will be REQUIRED to complete the installation."

# Perform system checks
check_system
check_secure_boot
PURGE_NEEDED=1
if check_existing_driver; then
    PURGE_NEEDED=0
fi

if ! ask_question "Do you want to proceed with the NVIDIA driver installation?"; then
    print_info "Installation cancelled by user."
    exit 0
fi

# Step 1: Purge existing drivers if necessary
if [[ "$PURGE_NEEDED" -eq 0 ]]; then
    print_info "Purging all existing NVIDIA packages to ensure a clean installation..."
    sudo apt-get purge -y '*nvidia*'
    sudo apt-get autoremove -y
    print_success "Old NVIDIA packages have been removed."
fi

# Step 2: Add the official graphics-drivers PPA
print_info "Adding the graphics-drivers PPA..."
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt-get update
print_success "PPA added successfully."

# Step 3: Detect and install the recommended driver
print_info "Detecting the recommended driver for your hardware..."
# The ubuntu-drivers command automatically finds the best package
RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep recommended | awk '{print $3}')

if [ -z "$RECOMMENDED_DRIVER" ]; then
    print_error "Could not automatically detect a recommended driver."
    print_info "Please check your hardware compatibility or install manually."
    exit 1
fi

print_success "Recommended driver found: ${RECOMMENDED_DRIVER}"

if ask_question "Do you want to install the '${RECOMMENDED_DRIVER}' driver?"; then
    print_info "Installing ${RECOMMENDED_DRIVER}..."
    sudo apt-get install -y "${RECOMMENDED_DRIVER}"
    print_success "Driver installation command issued."
else
    print_info "Installation cancelled."
    exit 0
fi

# Final message
echo ""
print_success "=== NVIDIA Driver Installation Complete ==="
print_warning "The system MUST be rebooted for the new driver to load."
echo ""
print_info "After rebooting, you can verify the installation by running:"
print_info "  nvidia-smi"
echo ""

if ask_question "Do you want to reboot now?"; then
    print_info "Rebooting system..."
    sudo reboot
else
    print_info "Please reboot your system manually to complete the installation."
fi

exit 0
