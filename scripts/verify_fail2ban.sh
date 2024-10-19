#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if systemctl is-active --quiet fail2ban; then
  echo "Fail2Ban is running."
else
  echo "Fail2Ban is not running. Please install and start by following this guide:
  Instructions: https://pimylifeup.com/raspberry-pi-fail2ban/
Then, reboot the system to run the script again." >&2
  exit 1
fi