#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# Grant execute permissions to all scripts in the 'scripts' directory
if [ "$granted_scripts_permissions" != "True" ]; then
  chmod +x /home/$USER/n8n-supabase-pi/scripts/*.sh
  chmod +x /home/$USER/n8n-supabase-pi/setup_part2.sh
fi

# Configure setup
. /home/$USER/n8n-supabase-pi/scripts/configure_setup.sh

# Mark granting script permissions as completed
if [ "$granted_scripts_permissions" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^granted_scripts_permissions=/d' "$CONFIG_FILE"
  echo "granted_scripts_permissions=True" >> "$CONFIG_FILE"
fi

# # Install Azure CLI
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Configure .env file
. /home/$USER/n8n-supabase-pi/scripts/configure_env.sh

echo "Commencing with Setup Part 1..."

# Update the system
sudo apt update && sudo apt full-upgrade -y

# Install Argon One PI 4 V2 Power Button & Fan Control
if [ "$install_argon_one" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/install_argon_one.sh
fi

# Install Raspberry Pi Connect
if [ "$install_rpi_connect" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/install_rpi_connect.sh
fi

# Install Docker
. /home/$USER/n8n-supabase-pi/scripts/install_docker.sh

# Install Network Time Protocol (NTP)
. /home/$USER/n8n-supabase-pi/scripts/install_ntp.sh

# Install Fail2Ban
if [ "$install_fail2ban" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/install_fail2ban.sh
fi

# Install Uncomplicated Firewall (UFW)
if [ "$install_ufw" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/install_ufw.sh
fi

# Mount Database Drive
if [ "$mount_database_drive" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/mount_database_drive.sh
fi

if [ "$completed_setup_part_1" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^completed_setup_part_1=/d' "$CONFIG_FILE"
  echo "completed_setup_part_1=True" >> "$CONFIG_FILE"
fi

# Reboot the system
echo "Setup Part 1 complete. Please reboot before running Setup Part 2 script."
