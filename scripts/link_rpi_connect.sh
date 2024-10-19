#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$linked_rpi_connect" == "True" ]; then
  echo "Raspberry Pi Connect is already linked."
elif [ "$installed_rpi_connect" == "True" ]; then
  echo "Link to Raspberry Pi Connect"

  # Link our Raspberry Pi device with a Connect Account
  rpi-connect signin

  # Update the setup.conf file
  sed -i '/^linked_rpi_connect=/d' "$CONFIG_FILE"
  echo "linked_rpi_connect=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "Raspberry Pi Connect has been linked successfully."
else
  # Update the setup.conf file
  sed -i '/^linked_rpi_connect=/d' "$CONFIG_FILE"
  echo "linked_rpi_connect=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't link Raspberry Pi Connect because it isn't installed. Install Raspberry Pi Connect and try again."
  exit 1
fi