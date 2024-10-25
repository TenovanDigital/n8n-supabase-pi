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
  # Ensure the traefik network exists
  if ! sudo docker network ls | grep -q "traefik"; then
    echo "Traefik network not found. Creating traefik network..."
    sudo docker network create traefik
  fi

  # Install Portainer (our Web interface for Docker management)
  sudo docker pull portainer/portainer-ce:latest

  # Start up Portainer with Traefik labels
  sudo docker run -d \
    --name portainer \
    --restart always \
    -p 9000:9000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    --network traefik \
    -l "traefik.enable=true" \
    -l "traefik.http.routers.portainer.rule=Host(\`${SUBDOMAIN}.${DOMAIN_NAME}\`) && PathPrefix(\`/portainer\`)" \
    -l "traefik.http.routers.portainer.tls=true" \
    -l "traefik.http.routers.portainer.entrypoints=websecure" \
    -l "traefik.http.routers.portainer.tls.certresolver=myresolver" \
    -l "traefik.http.middlewares.portainer.headers.SSLRedirect=true" \
    -l "traefik.http.middlewares.portainer.headers.STSSeconds=315360000" \
    -l "traefik.http.middlewares.portainer.headers.browserXSSFilter=true" \
    -l "traefik.http.middlewares.portainer.headers.contentTypeNosniff=true" \
    -l "traefik.http.middlewares.portainer.headers.forceSTSHeader=true" \
    -l "traefik.http.middlewares.portainer.headers.SSLHost=${DOMAIN_NAME}" \
    -l "traefik.http.middlewares.portainer.headers.STSIncludeSubdomains=true" \
    -l "traefik.http.middlewares.portainer.headers.STSPreload=true" \
    -l "traefik.http.routers.portainer.middlewares=portainer@docker" \
    -l "traefik.http.services.portainer.loadbalancer.server.port=9000" \
    portainer/portainer-ce:latest

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

  # Confirmation message
  echo "Portainer has been installed successfully."
else
  # Update the setup.conf file
  sed -i '/^installed_portainer=/d' "$CONFIG_FILE"
  echo "installed_portainer=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't install Portainer because Docker isn't installed. Install Docker and try again."
  exit 1
fi