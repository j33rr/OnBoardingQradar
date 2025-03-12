#!/bin/bash
echo "
Automation for Enabling Logs For 
╔──────────────────────────────────────────╗
│    _____                                 │
│ __|_    |__ ____ ____   _ __   _ __ __   │
│|    |      |    |    \ | |  | | |\ ` /   │
│|    |_     |    |     \| |  |_| |/   \   │
│|______|  __|____|__/\____|______/__/\_\  │
│   |_____|                                │
╚──────────────────────────────────────────╝
By j33rr.
"
# Step 1: Prompt the user for the destination IP address
read -p "Enter the destination IP address for the Event Collector/QRadar server: " DEST_IP

# Validate the input (basic IP format check)
if [[ ! $DEST_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid IP address format. Please enter a valid IP address."
    exit 1
fi

# Step 2: Enable Command Line Logging
echo "Step 1: Enabling command line logging..."
sudo bash -c 'cat <<EOF >> /etc/profile
function log2syslog
{
    declare COMMAND
    COMMAND=$(fc -ln -0)
    logger -p local7.notice -t bash -i -- "<terminal_command> ${USER}:${COMMAND}"
}
trap log2syslog DEBUG
EOF'

# Step 3: Enable General Logging + Command Line Logging
echo "Step 2: Configuring rsyslog..."

# Add local7.* /var/log/cmdline before the MODULES block
sudo sed -i '/^#################$/i local7.* /var/log/cmdline' /etc/rsyslog.conf

# Add remote logging configuration at the end of the file
sudo bash -c 'cat <<EOF >> /etc/rsyslog.conf
*.info;mail.none;authpriv.none;daemon.none;cron.none @@'"$DEST_IP"':514
authpriv.* @@'"$DEST_IP"':514
local7.notice @@'"$DEST_IP"':514
EOF'

# Step 4: Restart rsyslog service
echo "Step 3: Restarting rsyslog service..."
sudo systemctl restart rsyslog

# Check rsyslog status
echo "Checking rsyslog status..."
sudo systemctl status rsyslog --no-pager

# Step 5: Reload /etc/profile
echo "Step 4: Reloading /etc/profile..."
source /etc/profile

echo "Logging setup completed successfully!"
