#!/bin/sh

# Create VPN client check script
CHECK_SCRIPT="/usr/bin/vpn_checker.sh"

cat << EOF > $CHECK_SCRIPT
#!/bin/sh

# Check if the VPN client is active
vpn_status=\$(service softethervpnclient status)

if echo "\$vpn_status" | grep -q "active (running)"; then
    echo "VPN client is active."
else
    echo "VPN client is not active. Restarting..."

    # Delete existing vpnclient files
    rm -f /tmp/vpnclient*

    # Start the VPN client
    service softethervpnclient start

    echo "VPN client restarted."
fi
EOF

# Make the check script executable
chmod +x $CHECK_SCRIPT

# Add cron job to check VPN client every minute
CRON_CMD="*/1 * * * * $CHECK_SCRIPT >/dev/null 2>&1"
(crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -

echo "VPN client check script created: $CHECK_SCRIPT"
echo "Cron job added to check VPN client every minute."
