#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$configured_port_forwarding" == "True" ]; then
  echo "Port Forwarding is already configured."
else
  # Prompt user to configure Port Forwarding settings in their router
  # Pause to prompt user to configure Port Forwarding
  N8N_PORT=$(awk -F= '$1 == "N8N_PORT" {print $2}' /home/$USER/n8n-supabase-pi/.env)
  echo "
  Next, you need to set up Port Forwarding in your router to allow external access to n8n and Traefik. You should forward the following ports:
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port ${N8N_PORT:-5678} (n8n)
  "
  read -p "*******************************************************************************
  Press [Enter] when you have set up Port Forwarding."

  # Update the setup.conf file
  sed -i '/^configured_port_forwarding=/d' "$CONFIG_FILE"
  echo "configured_port_forwarding=True" >> "$CONFIG_FILE"
fi