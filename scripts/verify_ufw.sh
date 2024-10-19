#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

## CHANGE THIS. UFW ISN'T ENABLED, YET!
if command -v ufw > /dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
  echo "UFW is installed and active."

  # Enable UFW
  sudo ufw enable
else
  echo "UFW is not properly installed or not active. Please install and enable UFW by running:
  sudo apt-get install -y ufw
  sudo ufw allow ssh
  sudo ufw allow 5678
  sudo ufw enable
Then, reboot the system to run the script again." >&2
  exit 1
fi