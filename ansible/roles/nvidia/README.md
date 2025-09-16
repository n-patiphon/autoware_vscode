# nvidia

This role installs NVIDIA GPU drivers on Ubuntu systems for use with Autoware and CUDA applications.

## Inputs

| Variable                          | Description                              | Default                    |
| --------------------------------- | ---------------------------------------- | -------------------------- |
| `min_nvidia_driver_version`       | Minimum required driver version          | `545`                      |
| `nvidia_driver_version`           | Driver version to install if not present | `580`                      |
| `nvidia_driver_ubuntu_repository` | Ubuntu PPA for NVIDIA drivers            | `ppa:graphics-drivers/ppa` |

## Manual Installation

Check if NVIDIA drivers meet the minimum version requirement (545):

```bash
nvidia-smi
```

Install NVIDIA drivers (if not already installed):

```bash
# Add NVIDIA driver repository
sudo add-apt-repository ppa:graphics-drivers/ppa

# Update the package list
sudo apt-get update

# Install prerequisites
sudo apt-get install -y software-properties-common build-essential dkms

# Install NVIDIA driver
sudo apt-get install -y nvidia-driver-580

# Verify installation
echo "Installation complete. A system reboot is recommended."
echo "After rebooting, run 'nvidia-smi' to verify the installation."
```
