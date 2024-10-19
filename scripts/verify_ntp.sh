#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if systemctl is-active --quiet ntp; then
  echo "NTP is running."
else
  echo "NTP is not running. Please install and start NTP by running:
  sudo apt-get install -y ntp
  sudo systemctl enable ntp
  sudo systemctl start ntp
Then, reboot the system to run the script again." >&2
  exit 1
fi