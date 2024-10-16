#!/bin/bash

# Verify that the user has been added to docker group
if groups | grep -q docker; then
  echo "User is part of the docker group."
else
  echo "User is not part of the docker group. Please add the user to the docker group by running:
  sudo usermod -aG docker $USER
Then, reboot the system to run the script again." >&2
  exit 1
fi

# Verify NTP installation and status
if systemctl is-active --quiet ntp; then
  echo "NTP is running."
else
  echo "NTP is not running. Please install and start NTP by running:
  sudo apt-get install -y ntp
  sudo systemctl enable ntp
  sudo systemctl start ntp
Then, reboot the system to run the script again." >&2
  exit 1
fi

# Verify Fail2Ban installation and status
if systemctl is-active --quiet fail2ban; then
  echo "Fail2Ban is running."
else
  echo "Fail2Ban is not running. Please install and start Fail2Ban by running:
  sudo apt-get install -y fail2ban
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban
Then, reboot the system to run the script again." >&2
  exit 1
fi

# Verify UFW installation and status
if command -v ufw > /dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
  echo "UFW is installed and active."
else
  echo "UFW is not properly installed or not active. Please install and enable UFW by running:
  sudo apt-get install -y ufw
  sudo ufw allow OpenSSH
  sudo ufw enable
Then, reboot the system to run the script again." >&2
  exit 1
fi

# # Verify Memcached installation and status
# if systemctl is-active --quiet memcached; then
#   echo "Memcached is running."
# else
#   echo "Memcached is not running. Please install and start Memcached by running:
#   sudo apt-get install -y memcached
#   sudo systemctl enable memcached
#   sudo systemctl start memcached
# Then, reboot the system to run the script again." >&2
#   exit 1
# fi

# Verify Docker installation works
if sudo docker info > /dev/null 2>&1; then
  echo "Docker installation verified successfully."
else
  echo "Docker installation verification failed. Please ensure Docker is properly installed by running:
  curl -sSL https://get.docker.com | sh
Then, reboot the system to run the script again." >&2
  exit 1
fi

# Enable user-lingering for Raspberry Pi Connect to auto-run each reboot
loginctl enable-linger $USER

# Now we need to link our Raspberry Pi device with a Connect Account
rpi-connect signin

# Pause to allow user to link the Raspberry Pi device to the Connect account
read -p "Please complete the Raspberry Pi Connect setup by following the instructions above and press [Enter] when done."

# Install Portainer (our Web interface for Docker management)
sudo docker pull portainer/portainer-ce:latest

# Start up Portainer
sudo docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# Get the local IP address of the Raspberry Pi
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Get the global IP address of the Raspberry Pi
GLOBAL_IP=$(curl -s ifconfig.me)

# Display the IP addresses to the user
echo "The local IP address of this device is: $LOCAL_IP"
echo "The global IP address of this device is: $GLOBAL_IP"

# Pause to allow user to complete Portainer account setup
read -p "Please complete the Portainer account setup by visiting http://$LOCAL_IP:9000. For more information, refer to the account setup instructions here: https://pimylifeup.com/raspberry-pi-portainer/. Press [Enter] when done."

# Instructions for updating the .env file
echo "Next, you need to update the .env file with the required environment variables. Use the following guides for reference:
- Supabase Guide: https://supabase.com/docs/guides/self-hosting/docker#securing-your-services/
- n8n Guide: https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#6-create-env-file

To save changes in nano, press CTRL + X, then Y to confirm saving, and Enter to finalize."

# Pause to ensure the user has read the instructions
read -p "Press [Enter] to open the .env file for editing once you have read the instructions above."

# Open the .env file for the user to update with required environment variables
nano /home/$USER/n8n-supabase-pi/.env

# Prompt user to configure DNS settings for n8n
read -p "Please ensure that you set up DNS records pointing to this global IP address ($GLOBAL_IP) for hosting n8n publicly. Refer to the DNS setup guide here: https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#4-dns-setup. Press [Enter] when done."

# Secure the .env file by changing its permissions
chmod 600 /home/$USER/n8n-supabase-pi/.env

# # Sign in to Azure to configure Key Vault
# echo "Please sign in to Azure to configure Key Vault."
# az login --use-device-code

# # Prompt user for Azure Key Vault name
# read -p "Please enter the name of your Azure Key Vault: " KEY_VAULT_NAME

# # Function to get environment variables with lazy loading from Memcached
# get_env_var() {
#   local VAR_NAME=$1
#   local CACHE_VALUE=$(echo "get $VAR_NAME" | nc localhost 11211)

#   if [[ "$CACHE_VALUE" == *"VALUE $VAR_NAME"* ]]; then
#     # Extract the actual cached value from the response
#     CACHE_VALUE=${CACHE_VALUE#*VALUE $VAR_NAME }
#     echo "$CACHE_VALUE" | awk '{print $1}'
#   else
#     echo "Fetching $VAR_NAME from Azure Key Vault..."
#     local AZURE_VALUE=$(az keyvault secret show --name $VAR_NAME --vault-name $KEY_VAULT_NAME --query value -o tsv)
    
#     if [ -n "$AZURE_VALUE" ]; then
#       # Cache the retrieved value in Memcached for 1 hour (3600 seconds)
#       echo "set $VAR_NAME \"$AZURE_VALUE\" 0 3600" | nc localhost 11211
#     else
#       echo "Failed to fetch $VAR_NAME from Azure Key Vault. Please check your network connection, ensure the Key Vault name is correct, and verify your Azure permissions." >&2
#       exit 1
#     fi
#   fi
# }

# # Fetch environment variables using the lazy loading function
# N8N_USER=$(get_env_var "n8n-user")
# N8N_PASSWORD=$(get_env_var "n8n-password")
# POSTGRES_PASSWORD=$(get_env_var "postgres-password")
# JWT_SECRET=$(get_env_var "jwt-secret")
# ANON_KEY=$(get_env_var "anon-key")
# SERVICE_ROLE_KEY=$(get_env_var "service-role-key")

# Navigate to the repository directory
cd /home/$USER/n8n-supabase-pi

# Create Docker volume folders
docker volume create n8n_data
docker volume create traefik_data

# Pull Docker images as defined in the compose file
docker-compose pull

# Run Docker Compose to set up the rest of the services
docker-compose up -d

# Verify Docker Compose services are running
docker-compose ps

# Schedule automated reboot every Sunday at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * 0 /sbin/reboot") | crontab -

# Log setup completion
echo "Setup Part 2 complete. Services started successfully." >> /home/$USER/setup_log.txt
