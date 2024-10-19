#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_portainer" == "True" ]; then
  echo "Portainer is already installed."
elif [ "$installed_docker" == "True" ]; then
  # Install Portainer (our Web interface for Docker management)
  sudo docker pull portainer/portainer-ce:latest

  # Start up Portainer
  sudo docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

  # Get the local IP address of the Raspberry Pi
  LOCAL_IP=$(hostname -I | awk '{print $1}')

  # Display the IP address to the user
  echo "The local IP address of this device is: $LOCAL_IP"

  # Pause to allow user to complete Portainer account setup
  read -p "*******************************************************************************
  Please complete the Portainer account setup by visiting http://$LOCAL_IP:9000. For more information, refer to the account setup instructions here: https://pimylifeup.com/raspberry-pi-portainer/. Press [Enter] when done."

  # Update the setup.conf file
  sed -i '/^installed_portainer=/d' "$CONFIG_FILE"
  echo "installed_portainer=True" >> "$CONFIG_FILE"
else
  # Update the setup.conf file
  sed -i '/^installed_portainer=/d' "$CONFIG_FILE"
  echo "installed_portainer=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't install Portainer because Docker isn't installed. Install Docker and try again."
fi