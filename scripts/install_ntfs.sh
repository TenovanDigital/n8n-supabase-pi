#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_ntfs" == "True" ]; then
  echo "NTFS-3g driver is already installed."
else
  # Install ntfs-3g
  sudo apt install ntfs-3g

  # Update the setup.conf file
  sed -i '/^installed_ntfs=/d' "$CONFIG_FILE"
  echo "installed_ntfs=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "NTFS-3g driver has been installed successfully."
fi