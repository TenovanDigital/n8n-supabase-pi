#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Install Network Time Protocol (NTP) to sync time
sudo apt-get install -y ntp
sudo systemctl enable ntp
sudo systemctl start ntp

# Update the setup.conf file
sed -i '/^installed_ntp=/d' "$CONFIG_FILE"
echo "installed_ntp=True" >> "$CONFIG_FILE"