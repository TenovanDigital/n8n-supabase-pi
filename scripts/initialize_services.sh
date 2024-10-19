#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$initialized_services" == "True" ]; then
  echo "Services already initialized."
elif [ "$installed_docker" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^imported_n8n_workflows=/d' "$CONFIG_FILE"
  echo "imported_n8n_workflows=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't intialize services because Docker isn't installed. Install Docker and try again."
  exit 1
else
  echo "Initializing services..."

  # Navigate to the repository directory
  cd /home/$USER/n8n-supabase-pi

  # Pull Docker images as defined in the compose file
  docker compose pull

  # Run Docker Compose to set up the rest of the services
  docker compose up -d

  # Verify Docker Compose services are running
  docker compose ps

  # Update the setup.conf file
  sed -i '/^initialized_services=/d' "$CONFIG_FILE"
  echo "initialized_services=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "Services have been initialized successfully."
fi