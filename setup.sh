#!/bin/bash

# Autoware Development Environment Setup Script
# This script configures your host system for optimal Autoware development
#
# Usage:
#   ./setup.sh                    - Interactive mode with prompts
#   ./setup.sh /path/to/workspace - Quick setup mode (auto-yes to all questions)
#   ./setup.sh --help             - Show help information

# Function to show help
show_help() {
    echo "Autoware Development Environment Setup Script"
    echo ""
    echo "This script configures your host system for optimal Autoware development."
    echo "It sets up multicasting services, CycloneDDS configuration, shell enhancements,"
    echo "tmux configuration, required directories, and VS Code/devcontainer configurations."
    echo ""
    echo "USAGE:"
    echo "  $0                    Interactive mode with prompts"
    echo "  $0 /path/to/workspace Quick setup mode (auto-yes to all questions)"
    echo "  $0 --help             Show this help information"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                    # Interactive setup with prompts"
    echo "  $0 ~/autoware         # Quick setup for ~/autoware workspace"
    echo "  $0 /home/user/project # Quick setup for custom workspace"
    echo ""
    echo "FEATURES:"
    echo "  • Multicasting service installation and configuration"
    echo "  • CycloneDDS system optimization"
    echo "  • Enhanced shell with git prompt and bash completion"
    echo "  • Tmux installation and configuration"
    echo "  • Required directory creation for devcontainer development"
    echo "  • VS Code and devcontainer configuration deployment"
    echo "  • Automatic backup of existing configurations"
    echo ""
    echo "BACKUP BEHAVIOR:"
    echo "  Existing .vscode and .devcontainer directories are moved to:"
    echo "  autoware_vscode/backup/TIMESTAMP/.vscode"
    echo "  autoware_vscode/backup/TIMESTAMP/.devcontainer"
    echo ""
}

set -e

# Check for help flag
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$SCRIPT_DIR/local"

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

# Global variables for auto-answering questions and backup timestamp
AUTO_YES=false
BACKUP_TIMESTAMP=""

# Function to get or create backup timestamp
get_backup_timestamp() {
    if [[ -z "$BACKUP_TIMESTAMP" ]]; then
        BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    fi
    echo "$BACKUP_TIMESTAMP"
}

# Function to ask yes/no questions with default "yes"
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
    echo -e "${BLUE}[Y/n/A] (default: all yes, Y=yes once, A=all yes):${NC} \c"
    read -r response
    
    # Default to "all yes" if empty response
    response=${response:-a}
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        [aA]|[aA][lL][lL]) 
            AUTO_YES=true
            print_info "All remaining questions will be answered 'yes'"
            return 0 ;;
        *) return 1 ;;
    esac
}

# Function to check if a file exists
check_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        print_error "Required file not found: $file"
        return 1
    fi
    return 0
}

# Function to backup workspace configuration directories to repository
backup_workspace_config() {
    local source_dir="$1"
    local config_name="$2"  # .vscode or .devcontainer
    
    if [[ -d "$source_dir" ]]; then
        # Create backup directory if it doesn't exist
        local backup_base_dir="$SCRIPT_DIR/backup"
        mkdir -p "$backup_base_dir"
        
        local timestamp
        timestamp=$(get_backup_timestamp)
        local timestamped_backup_dir="$backup_base_dir/$timestamp"
        mkdir -p "$timestamped_backup_dir"
        
        local backup_dir="$timestamped_backup_dir/$config_name"
        
        print_info "Moving existing $config_name to repository backup: $backup_dir"
        mv "$source_dir" "$backup_dir"
        print_success "Moved to: $backup_dir"
        return 0
    fi
    return 1
}

# Function to backup existing files or directories (for non-workspace files)
backup_file() {
    local file="$1"
    if [[ -f "$file" ]] || [[ -d "$file" ]]; then
        local backup
        backup="$file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up existing file/directory to: $backup"
        cp -r "$file" "$backup"
    fi
}

print_info "=== Autoware Development Environment Setup ==="
print_info "This script will configure your system for Autoware development."

# Check if workspace path was provided as command line argument
if [[ $# -eq 1 ]]; then
    workspace_path="$1"
    AUTO_YES=true
    print_info "Quick setup mode: Using provided workspace path and auto-answering 'yes' to all questions"
    print_info "Question options:"
    print_info "  • All questions will be automatically answered 'yes'"
else
    print_info "Question options:"
    print_info "  • Press Enter or A/a = Yes to ALL remaining questions (default)"
    print_info "  • Type Y/y = Yes to current question only"
    print_info "  • Type N/n = No"
    
    # Ask for workspace path
    echo ""
    echo -e "${YELLOW}Enter the path to your Autoware workspace:${NC}"
    echo -e "${BLUE}(default: ~/autoware):${NC} \c"
    read -r workspace_path
    
    # Set default workspace path
    workspace_path=${workspace_path:-~/autoware}
fi

# Expand tilde if present
workspace_path="${workspace_path/#\~/$HOME}"

# Check if workspace exists
if [[ ! -d "$workspace_path" ]]; then
    print_error "Workspace directory does not exist: $workspace_path"
    print_error "Please create the workspace directory first or specify an existing one."
    exit 1
fi

print_success "Using workspace: $workspace_path"

# Check for existing .vscode and .devcontainer directories
vscode_exists=false
devcontainer_exists=false

if [[ -d "$workspace_path/.vscode" ]]; then
    vscode_exists=true
    print_warning "Found existing .vscode directory in workspace"
fi

if [[ -d "$workspace_path/.devcontainer" ]]; then
    devcontainer_exists=true
    print_warning "Found existing .devcontainer directory in workspace"
fi

if [[ "$vscode_exists" == true ]] || [[ "$devcontainer_exists" == true ]]; then
    echo ""
    print_warning "Existing VS Code/devcontainer configuration found!"
    if ! ask_question "Do you want to continue? (Existing files may be overridden)"; then
        print_info "Setup cancelled by user"
        exit 0
    fi
fi

# 1. Multicasting service setup
if ask_question "Do you want to install the multicasting service?"; then
    if check_file_exists "$LOCAL_DIR/multicasting.service"; then
        print_info "Installing multicasting service..."
        sudo cp "$LOCAL_DIR/multicasting.service" /etc/systemd/system/multicasting.service
        print_success "Multicasting service file copied successfully"
        
        if ask_question "Do you want to enable the multicasting service?"; then
            print_info "Enabling multicasting service..."
            sudo systemctl daemon-reload
            sudo systemctl enable multicasting.service
            print_success "Multicasting service enabled"
        fi
    fi
else
    print_info "Skipping multicasting service setup"
fi

# 2. CycloneDDS configuration
if ask_question "Do you want to install CycloneDDS system configuration?"; then
    if check_file_exists "$LOCAL_DIR/10-cyclone-max.conf"; then
        print_info "Installing CycloneDDS sysctl configuration..."
        sudo cp "$LOCAL_DIR/10-cyclone-max.conf" /etc/sysctl.d/10-cyclone-max.conf
        print_success "CycloneDDS configuration file copied successfully"
        
        if ask_question "Do you want to apply CycloneDDS settings immediately?"; then
            print_info "Applying CycloneDDS network settings..."
            sudo sysctl -w net.core.rmem_max=2147483647
            sudo sysctl -w net.ipv4.ipfrag_time=3
            sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728
            print_success "CycloneDDS network settings applied"
        fi
    fi
else
    print_info "Skipping CycloneDDS configuration"
fi

# 3. Shell configuration (git prompt and bash completion)
if ask_question "Do you want to configure enhanced shell with git prompt?"; then
    if check_file_exists "$LOCAL_DIR/git.conf"; then
        # Check if git configuration already exists in ~/.bashrc
        if grep -q "GIT_PS1_SHOWDIRTYSTATE" ~/.bashrc 2>/dev/null; then
            print_warning "Git prompt configuration already exists in ~/.bashrc"
            if ask_question "Do you want to update the existing configuration?"; then
                # Remove existing git configuration lines
                print_info "Removing existing git configuration from ~/.bashrc..."
                sed -i '/export GIT_PS1_/d' ~/.bashrc
                sed -i '/export PROMPT_COMMAND=/d' ~/.bashrc
                sed -i '/PRE=/d' ~/.bashrc
            else
                print_info "Keeping existing git configuration"
            fi
        fi
        
        if ! grep -q "GIT_PS1_SHOWDIRTYSTATE" ~/.bashrc 2>/dev/null; then
            print_info "Adding git prompt configuration to ~/.bashrc..."
            echo "" >> ~/.bashrc
            echo "# Git prompt configuration (added by Autoware setup)" >> ~/.bashrc
            cat "$LOCAL_DIR/git.conf" >> ~/.bashrc
            print_success "Git prompt configuration added to ~/.bashrc"
        fi
        
        # Install bash completion
        if ! dpkg -l | grep -q bash-completion; then
            print_info "Installing bash completion..."
            sudo apt update && sudo apt install -y bash-completion
            print_success "Bash completion installed"
        else
            print_info "Bash completion already installed"
        fi
    fi
else
    print_info "Skipping shell configuration"
fi

# 4. Tmux installation and configuration
if ask_question "Do you want to install and configure tmux?"; then
    # Install tmux if not already installed
    if ! command -v tmux &> /dev/null; then
        print_info "Installing tmux..."
        sudo apt update && sudo apt install -y xclip tmux
        print_success "Tmux installed successfully"
    else
        print_info "Tmux already installed"
    fi
    
    # Configure tmux
    if check_file_exists "$LOCAL_DIR/tmux.conf"; then
        if [[ -f ~/.tmux.conf ]]; then
            backup_file ~/.tmux.conf
        fi
        
        print_info "Installing tmux configuration..."
        cp "$LOCAL_DIR/tmux.conf" ~/.tmux.conf
        print_success "Tmux configuration installed to ~/.tmux.conf"
    fi
else
    print_info "Skipping tmux installation and configuration"
fi

# 5. Create required directories for devcontainer
if ask_question "Do you want to create required directories for devcontainer development?"; then
    print_info "Creating required directories..."
    
    directories=(
        "$HOME/autoware_data"
        "$HOME/autoware_map"
        "$HOME/.ssh"
        "$HOME/.webauto"
        "$HOME/.config/Lichtblick"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_info "Creating directory: $dir"
            mkdir -p "$dir"
            print_success "Created: $dir"
        else
            print_info "Directory already exists: $dir"
        fi
    done
    
    print_success "All required directories are ready"
else
    print_info "Skipping directory creation"
fi

# 6. Copy workspace configuration files
if ask_question "Do you want to copy VS Code and devcontainer configuration to the workspace?"; then
    # Check if data directory exists in script location
    data_dir="$SCRIPT_DIR/workspace"
    if [[ -d "$data_dir" ]]; then
        print_info "Copying workspace configuration files..."
        
        # Copy .vscode directory if it exists
        if [[ -d "$data_dir/.vscode" ]]; then
            backup_workspace_config "$workspace_path/.vscode" ".vscode"
            cp -r "$data_dir/.vscode" "$workspace_path/"
            print_success "VS Code configuration copied to workspace"
        fi
        
        # Copy .devcontainer directory if it exists
        if [[ -d "$data_dir/.devcontainer" ]]; then
            backup_workspace_config "$workspace_path/.devcontainer" ".devcontainer"
            cp -r "$data_dir/.devcontainer" "$workspace_path/"
            print_success "Devcontainer configuration copied to workspace"
        fi
        
        print_success "Workspace configuration files installed"
    else
        print_warning "Configuration data directory not found: $data_dir"
        print_info "Skipping workspace configuration copy"
    fi
else
    print_info "Skipping workspace configuration copy"
fi

# Final message
echo ""
print_success "=== Setup Complete ==="
print_info "Your Autoware development environment has been configured!"
print_info "Workspace location: $workspace_path"
print_info ""
print_info "Next steps:"
print_info "1. Restart your terminal or run 'source ~/.bashrc' to apply shell changes"
print_info "2. Open your workspace in VS Code: 'code $workspace_path'"
print_info "3. Your devcontainer environment is now ready to use"
print_info ""
print_info "Configuration Review:"
print_info "• Check $workspace_path/.vscode/ for VS Code settings, launch configs, and tasks"
print_info "• Check $workspace_path/.devcontainer/ for container setup and development tools"
print_info "• Review available debug configurations, build tasks, and development features"

exit 0
