#!/bin/bash

echo "
Automation for Removing Logs Configuration
╔──────────────────────────────────────────╗
│    _____                                 │
│ __|_    |__ ____ ____   _ __   _ __ __   │
│|    |      |    |    \ | |  | | |\ ` /   │
│|    |_     |    |     \| |  |_| |/   \   │
│|______|  __|____|__/\____|______/__/\_\  │
│   |_____|                                │
╚──────────────────────────────────────────╝
By j33rr."

# Step 1: Remove the log2syslog function and trap command from /etc/profile
echo "Step 1: Removing command line logging configuration from /etc/profile..."
sudo sed -i '/^function log2syslog/,/^trap log2syslog DEBUG/d' /etc/profile

# Step 2: Remove the local7.* /var/log/cmdline line from /etc/rsyslog.conf
echo "Step 2: Removing local7.* /var/log/cmdline from /etc/rsyslog.conf..."
sudo sed -i '/^local7.* \/var\/log\/cmdline/d' /etc/rsyslog.conf

# Step 3: Remove the remote logging configuration from /etc/rsyslog.conf
echo "Step 3: Removing remote logging configuration from /etc/rsyslog.conf..."
sudo sed -i '/^*.info;mail.none;authpriv.none;daemon.none;cron.none @@.*:514/d' /etc/rsyslog.conf
sudo sed -i '/^authpriv.* @@.*:514/d' /etc/rsyslog.conf
sudo sed -i '/^local7.notice @@.*:514/d' /etc/rsyslog.conf

# Step 4: Restart rsyslog service
echo "Step 4: Restarting rsyslog service..."
sudo systemctl restart rsyslog

# Check rsyslog status
echo "Checking rsyslog status..."
sudo systemctl status rsyslog --no-pager

# Step 5: Reload /etc/profile
echo "Step 5: Reloading /etc/profile..."
source /etc/profile

echo "Logging configuration removal completed successfully!"
