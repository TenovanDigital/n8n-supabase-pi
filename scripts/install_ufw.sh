#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_ufw" == "True" ]; then
  echo "UFW is already installed."
else
  # Install Uncomplicated Firewall (UFW) and enable it
  sudo apt-get install -y ufw
  sudo ufw allow ssh
  # Allow port 5678 for n8n
  sudo ufw allow 5678
  # Allow ports 80 and 443 for traefik
  sudo ufw allow 80
  sudo ufw allow 443

  # Update the setup.conf file
  sed -i '/^installed_ufw=/d' "$CONFIG_FILE"
  echo "installed_ufw=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "UFW has been installed successfully."
fi