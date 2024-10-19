#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_exfat" == "True" ]; then
  echo "exFAT filesystem driver is already installed."
else
  # Install exfat
  sudo apt install exfat-fuse
  sudo apt install exfat-utils

  # Update the setup.conf file
  sed -i '/^installed_exfat=/d' "$CONFIG_FILE"
  echo "installed_exfat=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "exFAT filesystem driver has been installed successfully."
fi