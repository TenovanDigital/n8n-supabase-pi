#!/bin/bash

# Start by updating the system
sudo apt update && sudo apt full-upgrade -y

# Prompt the user to install the Argon One management system (for the case fan)
echo "Do you want to install the Argon One management system (for the case fan)? (y/n)"
read -r install_argon
if [[ "$install_argon" =~ ^[Yy]$ ]]; then
    curl https://download.argon40.com/argon1.sh | bash
else
    echo "Skipping Argon One management system installation."
fi

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

# Install Docker
curl -sSL https://get.docker.com | sh

# Add your user to the "docker" group
sudo usermod -aG docker $USER

# # Install Azure CLI
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Network Time Protocol (NTP) to sync time
sudo apt-get install -y ntp
sudo systemctl enable ntp
sudo systemctl start ntp

# Install Fail2Ban for security
sudo apt-get install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Instructions for updating the .env file
echo "
You need to update the jail.local file with the correct values:
- Instructions: https://pimylifeup.com/raspberry-pi-fail2ban/

To save changes in nano, press CTRL + X, then Y to confirm saving, and Enter to finalize.
"

# Pause to ensure the user has read the instructions
read -p "Press [Enter] to open the .env file for editing once you have read the instructions above."

# Open the jail.local file for the user to update
sudo nano /etc/fail2ban/jail.local

sudo service fail2ban restart

# Install Uncomplicated Firewall (UFW) and enable it
sudo apt-get install -y ufw
sudo ufw allow ssh
# Allow port 5678 for n8n webhook access
sudo ufw allow 5678
sudo ufw enable

# # Install Memcached for caching Azure Key Vault secrets
# sudo apt-get install -y memcached
# sudo systemctl enable memcached
# sudo systemctl start memcached

# Copy the .env.example file to .env for user configuration
cd /home/$USER/n8n-supabase-pi
cp .env.example .env

# Reboot the system
echo "Rebooting system to apply changes. After reboot, please manually run the part 2 setup script to continue."
sudo reboot
