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
  ./scripts/link_rpi_connect.sh
fi

# Install Portainer (our Web interface for Docker management)
if [ "$install_portainer" == "True" ]; then
  ./scripts/install_portainer.sh
fi

# Configure DNS settings for n8n
if [ "$configured_dns" != "True" ]; then
  ./scripts/configure_dns.sh
fi

# Configure Port Forwarding in router
if [ "$configured_port_forwarding" != "True" ]; then
  ./scripts/configure_port_forwarding.sh
fi

# Verify Docker installation and that the user has been added to docker group
if [ "$verified_docker" != "True" ]; then
  ./scripts/verify_docker.sh
fi

# Verify NTP installation and status
if [ "$verified_ntp" != "True" ]; then
  ./scripts/verify_ntp.sh
fi

# Verify Fail2Ban installation and status
if [ "$install_fail2ban" == "True" ] && [ "$verified_fail2ban" != "True" ]; then
  ./scripts/verify_fail2ban.sh
fi

# Verify UFW installation
if [ "$install_ufw" == "True" ] && [ "$verified_ufw" != "True" ]; then
  ./scripts/verify_ufw.sh
fi

if [ "$initialized_docker_compose" != "True" ]; then
  # Navigate to the repository directory
  cd /home/$USER/n8n-supabase-pi

  # Pull Docker images as defined in the compose file
  docker compose pull

  # Run Docker Compose to set up the rest of the services
  docker compose up -d

  # Verify Docker Compose services are running
  docker compose ps

  # Update the setup.conf file
  sed -i '/^initialized_docker_compose=/d' "$CONFIG_FILE"
  echo "initialized_docker_compose=True" >> "$CONFIG_FILE"
fi

# Schedule automated reboot every Sunday at 3 AM
if [ "$scheduled_weekly_reboot" != "True" ]; then
  (crontab -l 2>/dev/null; echo "0 3 * * 0 /sbin/reboot") | crontab -

  # Update the setup.conf file
  sed -i '/^scheduled_weekly_reboot=/d' "$CONFIG_FILE"
  echo "scheduled_weekly_reboot=True" >> "$CONFIG_FILE"
fi

# Import n8n AI-Agent Workflows (See https://docs.n8n.io/hosting/cli-commands/#workflows_1)
if [ "$imported_n8n_workflows" != "True" ]; then
  docker exec -u node -it n8n n8n import:workflow --input=My_workflow.json

  # Update the setup.conf file
  sed -i '/^imported_n8n_workflows=/d' "$CONFIG_FILE"
  echo "imported_n8n_workflows=True" >> "$CONFIG_FILE"
fi

# Log setup completion
echo "Setup Part 2 complete. Services started successfully." >> /home/$USER/setup_log.txt
