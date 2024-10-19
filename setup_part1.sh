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
if [ "$configured_setup" != "True" ]; then
  ./scripts/configure_setup.sh
fi

# Mark granting script permissions as completed
if [ "$granted_scripts_permissions" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^granted_scripts_permissions=/d' "$CONFIG_FILE"
  echo "granted_scripts_permissions=True" >> "$CONFIG_FILE"
fi

# # Install Azure CLI
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Configure .env file
if [ "$configured_env" != "True" ]; then
  ./scripts/configure_env.sh
fi

echo "Commencing with Setup Part 1..."

# Update the system
sudo apt update && sudo apt full-upgrade -y

# Install Argon One PI 4 V2 Power Button & Fan Control
if [ "$install_argon_one" == "True" ] && [ "$installed_argon_one" != "True" ]; then
  curl https://download.argon40.com/argon1.sh | bash

  # Update the setup.conf file
  sed -i '/^installed_argon_one=/d' "$CONFIG_FILE"
  echo "installed_argon_one=True" >> "$CONFIG_FILE"
fi

# Install Raspberry Pi Connect
if [ "$install_rpi_connect" == "True" ] && [ "$installed_rpi_connect" != "True" ]; then
  ./scripts/install_rpi_connect.sh
fi

# Install Docker
if [ "$installed_docker" != "True" ]; then
  ./scripts/install_docker.sh
fi

# Install Network Time Protocol (NTP)
if [ "$installed_ntp" != "True" ]; then
  ./scripts/install_ntp.sh
fi

# Install Fail2Ban
if [ "$install_fail2ban" == "True" ] && [ "$installed_fail2ban" != "True" ]; then
  ./scripts/install_fail2ban.sh
fi

# Install Uncomplicated Firewall (UFW)
if [ "$install_ufw" == "True" ] && [ "$installed_ufw" != "True" ]; then
  ./scripts/install_ufw.sh
fi

# Mount Database Drive
if [ "$mount_database_drive" == "True" ] && [ "$mounted_database_drive" != "True" ]; then
  ./scripts/mount_database_drive.sh
fi

# Update the setup.conf file
sed -i '/^completed_setup_part_1=/d' "$CONFIG_FILE"
echo "completed_setup_part_1=True" >> "$CONFIG_FILE"

# Reboot the system
echo "Setup Part 1 complete. Please reboot before running Setup Part 2 script."
