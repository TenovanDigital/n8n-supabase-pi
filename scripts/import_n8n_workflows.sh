#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$imported_n8n_workflows" == "True" ]; then
  echo "N8n worksflows already imported."
elif [ "$installed_docker" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^imported_n8n_workflows=/d' "$CONFIG_FILE"
  echo "imported_n8n_workflows=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't import n8n workflows because Docker isn't installed. Install Docker and try again."
  exit 1
elif [ "$initialized_services" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^imported_n8n_workflows=/d' "$CONFIG_FILE"
  echo "imported_n8n_workflows=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't import n8n workflows because the n8n service hasn't been initialized. Initialize services and try again."
  exit 1
else
  # Import n8n default Workflows (See https://docs.n8n.io/hosting/cli-commands/#workflows_1)
  docker exec -u node -it n8n n8n import:workflow --input=My_workflow.json

  # Update the setup.conf file
  sed -i '/^imported_n8n_workflows=/d' "$CONFIG_FILE"
  echo "imported_n8n_workflows=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "N8n worksflows have been imported successfully."
fi