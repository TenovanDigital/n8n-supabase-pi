#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$configured_dns" == "True" ]; then
  echo "DNS records are already configured."
else
  # Get the global IP address of the Raspberry Pi
  GLOBAL_IP=$(curl -s ifconfig.me)

  # Display the IP address to the user
  echo "The global IP address of this device is: $GLOBAL_IP"

  # Prompt user to configure DNS settings for n8n
  read -p "*******************************************************************************
  Please ensure that you set up DNS records pointing to this global IP address ($GLOBAL_IP) for hosting n8n publicly. Refer to the DNS setup guide here: https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#4-dns-setup. Press [Enter] when done."

  # Update the setup.conf file
  sed -i '/^configured_dns=/d' "$CONFIG_FILE"
  echo "configured_dns=True" >> "$CONFIG_FILE"
fi