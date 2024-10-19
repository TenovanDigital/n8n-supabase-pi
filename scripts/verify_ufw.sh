#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_ufw" == "True" ]; then
  echo "Enabling UFW..."

  # Enable UFW
  sudo ufw enable

  if command -v ufw > /dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
    echo "UFW is installed and active."
  else
    echo "UFW is not properly installed or not active. Please install and enable UFW and try again."
    exit 1
  fi
else
  echo "ERROR: Can't verify UFW because it isn't installed. Install UFW and try again."
  exit 1
fi