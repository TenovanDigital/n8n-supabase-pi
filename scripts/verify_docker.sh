#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_docker" == "True" ]; then
  # Verify Docker installation works
  if sudo docker info > /dev/null 2>&1; then
    echo "Docker installation verified successfully."
  else
    echo "Docker installation verification failed. Please ensure Docker is properly installed and try again."
    exit 1
  fi

  # Verify that the user has been added to docker group
  if groups | grep -q docker; then
    echo "User is part of the docker group."
  else
    echo "User is not part of the docker group. Please add the user to the docker group and try again."
    exit 1
  fi
else
  echo "ERROR: Can't verify Docker because it isn't installed. Install Docker and try again."
  exit 1
fi