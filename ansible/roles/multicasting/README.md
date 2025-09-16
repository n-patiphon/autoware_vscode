# multicasting

This role installs and configures a systemd service to enable loopback multicasting for ROS 2 communication.

## Inputs

None.

## Manual Installation

```bash
# Create the systemd service file
sudo tee /etc/systemd/system/multicasting.service > /dev/null << 'EOF'
[Unit]
Description=Enable loopback multicasting for ROS 2
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip link set lo multicast on
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable multicasting.service
sudo systemctl start multicasting.service

# Verify status
sudo systemctl status multicasting.service
```
