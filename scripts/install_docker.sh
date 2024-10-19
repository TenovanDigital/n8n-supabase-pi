#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_docker" == "True" ]; then
  echo "Docker is already installed."
else
  # Install Docker
  curl -sSL https://get.docker.com | sh

  # Add your user to the "docker" group
  sudo usermod -aG docker $USER

  # Update the setup.conf file
  sed -i '/^installed_docker=/d' "$CONFIG_FILE"
  echo "installed_docker=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "Docker has been installed successfully."
fi