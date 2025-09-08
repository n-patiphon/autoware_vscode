#!/bin/bash

# NVIDIA Container Toolkit Installation Script
# This script installs the NVIDIA Container Toolkit following official documentation
#
# Usage:
#   ./nvidia_container_toolkit.sh        - Install with prompts
#   ./nvidia_container_toolkit.sh -y     - Install with auto-yes to all questions
#   ./nvidia_container_toolkit.sh --help - Show help information

# --- Boilerplate and Helper Functions (from your style guide) ---

# Function to show help
show_help() {
    echo "NVIDIA Container Toolkit Installation Script"
    echo ""
    echo "Installs the NVIDIA Container Toolkit to enable GPU support in Docker."
    echo "This script assumes you have NVIDIA drivers and Docker already installed."
    echo ""
    echo "USAGE:"
    echo "  $0        Install with confirmation prompts"
    echo "  $0 -y     Install with auto-yes to all questions"
    echo "  $0 --help Show this help information"
    echo ""
    echo "DOCUMENTATION:"
    echo "  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"
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

# Function to check for prerequisites like Docker and NVIDIA drivers
check_prerequisites() {
    print_info "Checking prerequisites..."
    local prereq_ok=true

    # Check for Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker before running this script."
        prereq_ok=false
    else
        print_success "Docker is installed."
    fi

    # Check for nvidia-smi (indicates drivers are installed)
    if ! command -v nvidia-smi &> /dev/null; then
        print_error "NVIDIA drivers do not appear to be installed (nvidia-smi not found)."
        print_info "Please install the appropriate NVIDIA drivers for your GPU first."
        prereq_ok=false
    else
        print_success "NVIDIA drivers appear to be installed."
    fi

    if [[ "$prereq_ok" == false ]]; then
        exit 1
    fi
}

# Function to check if the toolkit is already installed
check_existing_toolkit() {
    if command -v nvidia-ctk &> /dev/null; then
        print_warning "NVIDIA Container Toolkit appears to be already installed."
        nvidia-ctk --version
        if ! ask_question "Do you want to proceed with reinstallation?"; then
            print_info "Installation cancelled."
            exit 0
        fi
    fi
}

# --- Main Script ---

print_info "=== NVIDIA Container Toolkit Installation Script ==="
print_info "This script will enable GPU support for Docker containers."

# Perform prerequisite checks
check_prerequisites
check_existing_toolkit

if ! ask_question "Do you want to proceed with the installation?"; then
    print_info "Installation cancelled by user."
    exit 0
fi

# Step 1: Set up the NVIDIA repository and GPG key
print_info "Setting up the NVIDIA Container Toolkit repository..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/$(dpkg --print-architecture)/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
print_success "NVIDIA repository added successfully."

# Step 2: Update package list
print_info "Updating package index with NVIDIA repository..."
sudo apt-get update
print_success "Package index updated."

# Step 3: Install the NVIDIA Container Toolkit packages
print_info "Installing NVIDIA Container Toolkit packages..."
sudo apt-get install -y nvidia-container-toolkit
print_success "NVIDIA Container Toolkit installed successfully."

# Step 4: Configure Docker to use the NVIDIA runtime
print_info "Configuring Docker to use the NVIDIA runtime..."
sudo nvidia-ctk runtime configure --runtime=docker
print_success "Docker runtime configured."

# Step 5: Restart the Docker daemon
print_info "Restarting the Docker daemon to apply changes..."
sudo systemctl restart docker
print_success "Docker daemon restarted."

# Final message
echo ""
print_success "=== NVIDIA Container Toolkit Installation Complete ==="
print_info "Your system is now configured to run GPU-accelerated Docker containers."
echo ""

exit 0
