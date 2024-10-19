#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_ntp" == "True" ]; then
  echo "NTP is already installed."
else
  # Install Network Time Protocol (NTP) to sync time
  sudo apt-get install -y ntp
  sudo systemctl enable ntp
  sudo systemctl start ntp

  # Update the setup.conf file
  sed -i '/^installed_ntp=/d' "$CONFIG_FILE"
  echo "installed_ntp=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "NTP has been installed successfully."
fi