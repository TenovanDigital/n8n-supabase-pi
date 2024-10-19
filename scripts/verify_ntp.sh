#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_ntp" == "True" ]; then
  if systemctl is-active --quiet ntp; then
    echo "NTP is running."
  else
    echo "NTP is not running. Please ensure NTP is properly installed and try again."
    exit 1
  fi
else
  echo "ERROR: Can't verify NTP because it isn't installed. Install NTP and try again."
  exit 1
fi