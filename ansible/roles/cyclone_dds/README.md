# cyclone_dds

This role configures system parameters for optimal CycloneDDS performance in ROS 2 and Autoware applications.

## Inputs

None.

## Manual Installation

```bash
# Create CycloneDDS sysctl configuration file
sudo tee /etc/sysctl.d/10-cyclone-max.conf > /dev/null << 'EOF'
# CycloneDDS system configuration for optimized network performance

# Increase the max receive buffer size to 2GB
net.core.rmem_max=2147483647

# Reduce the ipfrag_time to 3 seconds for faster reassembly
net.ipv4.ipfrag_time=3

# Increase the memory available for IP fragmentation reassembly
net.ipv4.ipfrag_high_thresh=134217728
EOF

# Apply settings immediately
sudo sysctl -w net.core.rmem_max=2147483647
sudo sysctl -w net.ipv4.ipfrag_time=3
sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728
```
