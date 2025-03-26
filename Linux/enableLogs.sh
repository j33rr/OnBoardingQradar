#!/bin/bash

echo -e "
Automation for Enabling Logs Configuration
╔──────────────────────────────────────────╗
│    _____                                 │
│ __|_    |__ ____ ____   _ __   _ __ __   │
│|    |      |    |    \ | |  | | |\  /   │
│|    |_     |    |     \| |  |_| |/   \   │
│|______|  __|____|__/\____|______/__/\_\  │
│   |_____|                                │
╚──────────────────────────────────────────╝
By j33rr."
# Step 1: Detect the package manager and install rsyslog if not already installed
echo "Step 1: Checking and installing rsyslog..."

# Function to detect the package manager
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unsupported"
    fi
}

# Function to install rsyslog based on the package manager
install_rsyslog() {
    local pkg_manager="$1"
    case "$pkg_manager" in
        apt)
            sudo apt-get update
            sudo apt-get install -y rsyslog
            ;;
        yum)
            sudo yum install -y rsyslog
            ;;
        dnf)
            sudo dnf install -y rsyslog
            ;;
        zypper)
            sudo zypper install -y rsyslog
            ;;
        pacman)
            sudo pacman -S --noconfirm rsyslog
            ;;
        *)
            echo "Error: Unsupported package manager. Please install rsyslog manually."
            exit 1
            ;;
    esac
}

# Detect the package manager
pkg_manager=$(detect_package_manager)

# Check if rsyslog is installed
if ! command -v rsyslogd &> /dev/null; then
    echo "rsyslog is not installed. Installing rsyslog using $pkg_manager..."
    install_rsyslog "$pkg_manager"
else
    echo "rsyslog is already installed."
fi

# Step 2: Prompt the user for the destination IP address
read -p "Enter the destination IP address for the Event Collector/QRadar server: " DEST_IP

# Validate the input (basic IP format check)
if [[ ! $DEST_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid IP address format. Please enter a valid IP address."
    exit 1
fi

# Step 3: Enable Command Line Logging
echo "Step 2: Enabling command line logging..."
sudo bash -c 'cat <<EOF >> /etc/profile
function log2syslog
{
    declare COMMAND
    COMMAND=$(fc -ln -0)
    logger -p local7.notice -t bash -i -- "<terminal_command> ${USER}:${COMMAND}"
}
trap log2syslog DEBUG
EOF'

# Step 4: Enable General Logging + Command Line Logging
echo "Step 3: Configuring rsyslog..."

# Add local7.* /var/log/cmdline before the MODULES block
sudo sed -i '/^#################$/i local7.* /var/log/cmdline' /etc/rsyslog.conf

# Add remote logging configuration at the end of the file
sudo bash -c 'cat <<EOF >> /etc/rsyslog.conf
*.info;mail.none;authpriv.none;daemon.none;cron.none @@'"$DEST_IP"':514
authpriv.* @@'"$DEST_IP"':514
local7.notice @@'"$DEST_IP"':514
local6.* @@'"$DEST_IP"':514
local5.* @@'"$DEST_IP"':514
EOF'

# Step 5: Restart rsyslog service
echo "Step 4: Restarting rsyslog service..."
sudo systemctl restart rsyslog

# Check rsyslog status
echo "Checking rsyslog status..."
sudo systemctl status rsyslog --no-pager

# Step 6: Reload /etc/profile
echo "Step 5: Reloading /etc/profile..."
source /etc/profile

echo "Logging setup completed successfully!"
