# vcstool

This role installs [vcstool](https://github.com/dirk-thomas/vcstool), a version control system tool designed to make working with multiple repositories easier. It's particularly useful for ROS and Autoware development.

## Inputs

None.

## Manual Installation

```bash
# Install curl if not already installed
sudo apt update
sudo apt install -y curl

# Add vcstool repository
curl -s https://packagecloud.io/install/repositories/dirk-thomas/vcstool/script.deb.sh | sudo bash

# Update package index
sudo apt update

# Install vcstool
sudo apt install -y python3-vcstool

# Verify installation
vcs --version
```
