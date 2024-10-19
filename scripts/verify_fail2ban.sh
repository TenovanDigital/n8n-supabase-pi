#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_fail2ban" == "True" ]; then
  if systemctl is-active --quiet fail2ban; then
    echo "Fail2Ban is running."
  else
    echo "Fail2Ban is not running. Please ensure Fail2Ban is properly installed and try again."
    exit 1
  fi
else
  echo "ERROR: Can't verify Fail2Ban because it isn't installed. Install Fail2Ban and try again."
  exit 1
fi