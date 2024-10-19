#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Detect if the device has a desktop version or headless version of the OS
if [ -f /usr/bin/raspi-config ]; then
  if raspi-config nonint get_can_boot_to_desktop | grep -q 1; then
    # Desktop version detected
    echo "Desktop version detected, installing rpi-connect"
    sudo apt install -y rpi-connect
  else
    # Headless version detected
    echo "Headless version detected, installing rpi-connect-lite"
    sudo apt install -y rpi-connect-lite
  fi
else
  # Fallback to headless version if detection fails
  echo "Unable to detect OS type, installing rpi-connect-lite by default"
  sudo apt install -y rpi-connect-lite
fi

# Start the service
systemctl --user start rpi-connect

# Enable user-lingering for Raspberry Pi Connect to auto-run each reboot
loginctl enable-linger $USER

# Update the setup.conf file
sed -i '/^installed_rpi_connect=/d' "$CONFIG_FILE"
echo "installed_rpi_connect=True" >> "$CONFIG_FILE"