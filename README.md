# Autoware Development Environment

A comprehensive development environment setup for Autoware projects using VS Code DevContainers with Docker support.

## Overview

This repository provides a complete development environment for Autoware projects, featuring:

- **Docker-based development containers** with pre-configured Autoware environments
- **VS Code DevContainer integration** for seamless development experience
- **System optimization scripts** for host machine configuration
- **Multiple container variants** supporting different Autoware distributions
- **NVIDIA GPU support** for CUDA-enabled development

## Quick Start

### 1. Requirements

- **NVIDIA GPU**: For CUDA support, an NVIDIA GPU driver must be installed.
- **Docker**: Ensure Docker is installed and running on your system.
- **NVIDIA Container Toolkit**: Required for GPU support in Docker containers.
- **VS Code**: IDE for development with DevContainer support.
- **vcstool**: Command line tool for managing multiple repositories.

You can use the provided scripts in the `extras/` directory to install missing dependencies.

```bash
# Install NVIDIA drivers (if you have NVIDIA GPU)
./extras/nvidia.sh

# Install Docker
./extras/docker.sh

# Install NVIDIA Container Toolkit (for GPU support in containers)
./extras/nvidia_container_toolkit.sh

# Pull latest recommended Autoware image
docker pull ghcr.io/autowarefoundation/autoware:universe-devel-cuda

# Install vcstool
./extras/vcstool.sh

# Install VS Code
./extras/vscode.sh

# Install VS Code extensions
./extras/extensions.sh
```

### 2. Clone your Autoware workspace

```bash
# Clone the Autoware repository
cd ~
git clone https://github.com/autowarefoundation/autoware.git
cd autoware
mkdir -p src
# Import repositories using vcstool
vcs import src < autoware.repos
# Optional, for nightly packages
vcs import src < autoware-nightly.repos
```

### 3. Environment Setup

Configure your development environment:

```bash
# Interactive setup with prompts
./setup.sh

# Quick setup for specific workspace
./setup.sh ~/autoware

# View all options
./setup.sh --help
```

### 4. Development

1. Open VS Code.
2. "Ctrl+Shift+P" → "Dev Containers: Open Folder in Container...".
3. Select your Autoware workspace directory and click "Open".
4. Select devcontainer configuration from the list (`universe-devel-cuda` recommended).
5. Wait for the container to build.
6. Build workspace inside container:
   - `Ctrl+Shift+P` → `Tasks: Run Task` → `Build: Workspace (Release)`.
7. Wait till clangd finishes indexing. If not started, trigger it manually:
   - `Ctrl+Shift+P` → `clangd: Restart language server`.
8. Start coding!

## Repository Structure

```
├── setup.sh                         # Main environment setup script
├── extras/                          # Dependency installation scripts
│   ├── docker.sh                    # Docker installation
│   ├── extensions.sh                # VS Code extensions installation
│   ├── nvidia.sh                    # NVIDIA driver installation
│   └── nvidia_container_toolkit.sh  # NVIDIA container toolkit installation
│   └── vcstool.sh                   # vcstool installation
│   └── vscode.sh                    # VS Code installation
├── workspace/                       # DevContainer configurations
│   ├── .devcontainer/               # Container definitions
│   └── .vscode/                     # VS Code settings and tasks
├── local/                           # System configuration files
│   ├── multicasting.service         # Network multicasting service
│   ├── 10-cyclone-max.conf          # CycloneDDS optimization
│   ├── git.conf                     # Enhanced git prompt
│   └── tmux.conf                    # Tmux configuration
└── backup/                          # Automatic backups of overwritten configs
```

## Container Variants

### Core Development ([`core-devel`](workspace/.devcontainer/core-devel/devcontainer.json))
Minimal Autoware core packages

### Universe Development ([`universe-devel`](workspace/.devcontainer/universe-devel/devcontainer.json))
Complete Autoware universe packages

### Universe with CUDA ([`universe-devel-cuda`](workspace/.devcontainer/universe-devel-cuda/devcontainer.json))
Complete Autoware universe packages with NVIDIA CUDA support


## Usage

### Tmux
Tmux is not a part of the container. It supposed to be used from the host level. Please check the available tmux video tutorials for base usage. This repository contains a few handy bindings with `local/tmux.conf`. 

When you start working on your project after system startup, you can do it this way:
1. Run vscode and wait for the container to build.
2. Open terminal and run `tmux`.
3. Setup your terminal layout in order to have multiple panes:
  -  `Ctrl+b` then `Shift+%` to split the window vertically.
  -  `Ctrl+b` then `"` to split the window horizontally.
  -  `Ctrl+b` then arrow keys to navigate between panes.
4. Enter devcontainer:
   - `Ctrl+b` then `Ctrl+x` to broadcast command to all panes.
   - `cd` to your workspace.
   - `./.devcontainer/enter.sh`.
5. `Ctrl+b` then `Ctrl+x` to stop broadcasting.
6. Use `Ctrl+b` then `c` to create new tab if needed.

[Cheat sheet](https://tmuxcheatsheet.com/) will be helpful for you!

### Pre-defined tasks
Use `Ctrl+Shift+P` → "Tasks: Run Task" to access pre-defined tasks defined in `.vscode/tasks.json`. Check the file for details.

### Debugging

1. Build package in Debug mode via `Ctrl+Shift+P` → "Tasks: Run Task" → "Build: Package (Debug)".
2. Set breakpoints in source code.
3. In terminal, add extra arguments to launch `--launch-prefix 'gdbserver localhost:4242' --launch-prefix-filter your_executable`.

   Note: In case of component container, instead of `your_executable" use "component_container" or "component_container_mt`.

   Note: In case of debugging CUDA code, use `cuda-gdbserver` instead of `gdbserver`.

   For example:
   ```bash
    ros2 launch package_name launch_name --launch-prefix 'gdbserver localhost:4242' --launch-prefix-filter your_executable
    ros2 launch package_name launch_name --launch-prefix 'gdbserver localhost:4242' --launch-prefix-filter component_container_mt
    ros2 launch package_name launch_name --launch-prefix 'cuda-gdbserver localhost:4242' --launch-prefix-filter component_container
   ```
4. `Ctrl+Shift+D` → From dropdown, select "Launch gdb / cuda-gdb with server" → `F5`.
5. Debug!

### Visualization
Launch lichtblick (foxglove) with one of the following commands in the terminal:

```bash
# Default
foxglove

# With custom port
foxglove --port 8766

# With ROS arguments
foxglove use_sim_time:=True
```

You can use RTUI for ROS troubleshooting. Check `rtui --help` for usage.

### Pre-commit
Use `Ctrl+Shift+P` → `Tasks: Run Task` → `pre-commit: Run` → type the path to the directory where `.pre-commit-config.yaml` is located.

### Profiling
Container includes `valgrind` and `kcachegrind` for profiling. Please check their documentation for usage.

## Backup System

The setup script automatically backs up existing configurations:
- Existing `.vscode` and `.devcontainer` directories are moved to [`backup/`](backup/) with timestamps
- System configuration files are backed up before modification
- Easy restoration from backup directories
