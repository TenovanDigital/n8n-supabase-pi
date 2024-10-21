#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  echo "Configuration file $CONFIG_FILE not found. Exiting."
  exit 1
fi

# Only run if the Part 1 script has completed
if [ "$completed_setup_part_1" != "True" ]; then
  echo "Setup Part 1 has not been completed. Complete that step first. Exiting."
  exit 1
fi

echo "Commencing with Setup Part 2..."

# # Sign in to Azure to configure Key Vault
# echo "*******************************************************************************"
# az login --use-device-code
# read -p "Please sign in to Azure to configure Key Vault. Press [Enter] when done."

# Link Raspberry Pi device with a Connect Account
if [ "$install_rpi_connect" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/link_rpi_connect.sh
fi

# Verify Docker installation and that the user has been added to docker group
. /home/$USER/n8n-supabase-pi/scripts/verify_docker.sh

# Install Portainer (our Web interface for Docker management)
if [ "$install_portainer" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/install_portainer.sh
fi

# Configure DNS settings for n8n
. /home/$USER/n8n-supabase-pi/scripts/configure_dns.sh

# Configure Port Forwarding in router
. /home/$USER/n8n-supabase-pi/scripts/configure_port_forwarding.sh

# Verify NTP installation and status
. /home/$USER/n8n-supabase-pi/scripts/verify_ntp.sh

# Verify Fail2Ban installation and status
if [ "$install_fail2ban" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/verify_fail2ban.sh
fi

# Verify UFW installation
if [ "$install_ufw" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/verify_ufw.sh
fi

# Initialize Services
. /home/$USER/n8n-supabase-pi/scripts/initialize_services.sh

# Schedule automated reboot every Sunday at 3 AM
. /home/$USER/n8n-supabase-pi/scripts/schedule_weekly_reboot.sh

# Change the Postgres Password
. /home/$USER/n8n-supabase-pi/scripts/change_postgres_password.sh

# Import n8n default Workflows (See https://docs.n8n.io/hosting/cli-commands/#workflows_1)
if [ "$import_n8n_workflows" == "True" ]; then
  . /home/$USER/n8n-supabase-pi/scripts/import_n8n_workflows.sh
fi

if [ "$completed_setup_part_2" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^completed_setup_part_2=/d' "$CONFIG_FILE"
  echo "completed_setup_part_2=True" >> "$CONFIG_FILE"
fi

# Log setup completion
echo "Setup Part 2 complete. Services started successfully."
