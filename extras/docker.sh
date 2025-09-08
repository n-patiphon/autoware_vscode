#!/bin/bash

# Docker Installation Script
# This script installs Docker CE following the official Docker documentation
#
# Usage:
#   ./docker.sh        - Install Docker with prompts
#   ./docker.sh -y     - Install Docker with auto-yes to all questions
#   ./docker.sh --help - Show help information

# Function to show help
show_help() {
    echo "Docker Installation Script"
    echo ""
    echo "Installs Docker CE following official Docker documentation."
    echo ""
    echo "USAGE:"
    echo "  $0        Install Docker with confirmation prompts"
    echo "  $0 -y     Install Docker with auto-yes to all questions"
    echo "  $0 --help Show this help information"
    echo ""
    echo "DOCUMENTATION:"
    echo "  Installation: https://docs.docker.com/engine/install/ubuntu"
    echo "  Post-install: https://docs.docker.com/engine/install/linux-postinstall"
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
    
    # Check if auto-answer is enabled
    if [[ "$AUTO_YES" == true ]]; then
        echo -e "\n${YELLOW}$question${NC}"
        echo -e "${GREEN}[AUTO: YES]${NC}"
        return 0
    fi
    
    echo -e "\n${YELLOW}$question${NC}"
    echo -e "${BLUE}[Y/n] (default: yes):${NC} \c"
    read -r response
    
    # Default to "yes" if empty response
    response=${response:-y}
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Function to check if running on supported system
check_system() {
    print_info "Checking system compatibility..."
    
    # Check if running on Linux
    if [[ "$(uname)" != "Linux" ]]; then
        print_error "This script only supports Linux systems"
        exit 1
    fi
    
    # Check for Ubuntu/Debian
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS. /etc/os-release not found."
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        print_warning "This script is designed for Ubuntu/Debian. Your system: $ID"
        if ! ask_question "Do you want to continue anyway?"; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
    
    print_success "System check passed"
}

# Function to check if Docker is already installed
check_existing_docker() {
    if command -v docker &> /dev/null; then
        print_warning "Docker is already installed"
        docker --version
        if ! ask_question "Do you want to reinstall Docker?"; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
}

# Function to remove old Docker versions
remove_old_docker() {
    print_info "Removing old Docker versions if they exist..."
    
    local old_packages=(
        "docker.io"
        "docker-doc"
        "docker-compose"
        "docker-compose-v2"
        "podman-docker"
        "containerd"
        "runc"
    )
    
    for package in "${old_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            print_info "Removing $package..."
            sudo apt remove -y "$package" || true
        fi
    done
    
    print_success "Old Docker versions cleaned up"
}

print_info "=== Docker Installation Script ==="
print_info "This script will install Docker CE following official documentation"

# Perform system checks
check_system
check_existing_docker

if ! ask_question "Do you want to proceed with Docker installation?"; then
    print_info "Installation cancelled by user"
    exit 0
fi

# Step 1: Remove old Docker versions
if ask_question "Do you want to remove old Docker versions first? (recommended)"; then
    remove_old_docker
fi

# Step 2: Update package index and install prerequisites
print_info "Updating package index and installing prerequisites..."
sudo apt update
sudo apt install -y ca-certificates curl
print_success "Prerequisites installed"

# Step 3: Create keyrings directory and add Docker's GPG key
print_info "Setting up Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker's GPG key
print_info "Downloading Docker's GPG key..."
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
print_success "Docker GPG key added successfully"

# Step 4: Add Docker repository to APT sources
print_info "Adding Docker repository to APT sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with new repository
print_info "Updating package index with Docker repository..."
sudo apt update
print_success "Docker repository added successfully"

# Step 5: Install ackages
print_info "Installing Docker CE and related packages..."
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

print_success "Docker packages installed successfully"

# Step 6: Post-installation setup
print_info "Configuring Docker for non-root access..."

# Create docker group (might already exist)
if ! getent group docker > /dev/null 2>&1; then
    print_info "Creating docker group..."
    sudo groupadd docker
else
    print_info "Docker group already exists"
fi

# Add current user to docker group
print_info "Adding current user ($USER) to docker group..."
sudo usermod -aG docker "$USER"
print_success "User added to docker group"

# Step 7: Start and enable Docker service
print_info "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker
print_success "Docker service started and enabled"

# Step 8: Verify installation
print_info "Verifying Docker installation..."
if sudo docker run hello-world &> /dev/null; then
    print_success "Docker installation verified successfully"
else
    print_warning "Docker verification failed, but installation appears complete"
fi

# Final message
echo ""
print_success "=== Docker Installation Complete ==="
print_info "Docker CE has been successfully installed!"
echo ""
print_info "IMPORTANT POST-INSTALLATION STEPS:"
print_info "1. Log out and log back in for group changes to take effect"
print_info "   OR run: newgrp docker"
print_info "2. Test Docker without sudo: docker run hello-world"
print_info "3. Check Docker version: docker --version"
print_info "4. Check Docker Compose: docker compose version"
echo ""
print_info "INSTALLED COMPONENTS:"
print_info "• Docker CE (Community Edition)"
print_info "• Docker CLI"
print_info "• containerd.io"
print_info "• Docker Buildx plugin"
print_info "• Docker Compose plugin"
echo ""
print_info "Your user ($USER) has been added to the 'docker' group."
print_info "You can now run Docker commands without sudo after re-login."

exit 0
