#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_argon_one" == "True" ]; then
  echo "Argon One PI 4 V2 Power Button & Fan Control already installed."
else
  # Install Argon One PI 4 V2 Power Button & Fan Control
  curl https://download.argon40.com/argon1.sh | bash

  # Update the setup.conf file
  sed -i '/^installed_argon_one=/d' "$CONFIG_FILE"
  echo "installed_argon_one=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "Argon One PI 4 V2 Power Button & Fan Control has been installed successfully."
fi