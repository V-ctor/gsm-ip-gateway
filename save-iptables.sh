#!/bin/bash

# Save the current iptables rules to a file
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Create a systemd service to restore the iptables rules at boot time
cat > /etc/systemd/system/iptables-restore.service <<EOF
[Unit]
Description=Restore iptables rules

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
ExecStart=/sbin/ip6tables-restore /etc/iptables/rules.v6
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Create a symbolic link to the service file in the systemd multi-user.target directory
ln -s /etc/systemd/system/iptables-restore.service /etc/systemd/system/multi-user.target.wants/iptables-restore.service

# Reload the systemd daemon to read the new service file
systemctl daemon-reload

# Enable the service to start automatically at boot time
systemctl enable iptables-restore.service