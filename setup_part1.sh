#!/bin/bash

# Start by updating the system
sudo apt update && sudo apt full-upgrade -y

# Prompt the user to install the Argon One management system (for the case fan)
echo "*******************************************************************************
Do you want to install the Argon One management system (for the case fan)? (y/n)"
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

# Enable user-lingering for Raspberry Pi Connect to auto-run each reboot
loginctl enable-linger $USER

# Install Docker
curl -sSL https://get.docker.com | sh

# Add your user to the "docker" group
sudo usermod -aG docker $USER

# # Install Azure CLI
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Prompt the user to determine if they want to install Fail2Ban for security
echo "*******************************************************************************"
echo "Do you want to install Fail2Ban for security? (y/n)"
read -r install_fail2ban

if [[ "$install_fail2ban" =~ ^[Yy]$ ]]; then
    # Install Fail2Ban for security
    sudo apt-get install -y fail2ban

    # Copy default configuration to local configuration
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

    # Insert default Fail2Ban settings under [sshd] in jail.local
    sudo awk '
        BEGIN {insert=0}
        /^\[sshd\]/ {print; print "enabled = true\nfilter = sshd"; insert=1; next}
        {if (insert && /^[^\[]/) insert=0; if (!insert) print}
    ' /etc/fail2ban/jail.local | sudo tee /etc/fail2ban/jail.local.tmp && sudo mv /etc/fail2ban/jail.local.tmp /etc/fail2ban/jail.local

    # Prompt the user for Fail2Ban configuration values
    echo "*******************************************************************************"
    while true; do
        read -p "Enter ban time in seconds for Fail2Ban (e.g., 1800 for 30 minutes, -1 for permanent): " bantime
        if [[ "$bantime" =~ ^-?[0-9]+$ ]]; then
            break
        else
            echo "Invalid input. Please enter a numeric value for ban time."
        fi
    done

    while true; do
        read -p "Enter max retry attempts for Fail2Ban (e.g., 3): " maxretry
        if [[ "$maxretry" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid input. Please enter a numeric value for max retry attempts."
        fi
    done
    echo "*******************************************************************************"

    # Insert additional configuration values under [sshd] in jail.local
    sudo awk -v bantime="$bantime" -v maxretry="$maxretry" '
        BEGIN {insert=0}
        /^\[sshd\]/ {print; insert=1; next}
        insert == 1 && /^[^\[]/ {print "banaction = iptables-multiport\nbantime = " bantime "\nmaxretry = " maxretry; insert=0}
        {print}
    ' /etc/fail2ban/jail.local | sudo tee /etc/fail2ban/jail.local.tmp && sudo mv /etc/fail2ban/jail.local.tmp /etc/fail2ban/jail.local

    # Restart Fail2Ban service to apply the changes
    sudo service fail2ban restart

    # Confirmation message
    echo "Fail2Ban has been installed and configured successfully."
else
    echo "Skipping Fail2Ban installation."
fi

# Install Uncomplicated Firewall (UFW) and enable it
sudo apt-get install -y ufw
sudo ufw allow ssh
# Allow port 5678 for n8n
sudo ufw allow 5678
# Allow ports 80 and 443 for traefik
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# # Install Memcached for caching Azure Key Vault secrets
# sudo apt-get install -y memcached
# sudo systemctl enable memcached
# sudo systemctl start memcached

# Prompt the user to determine if they want to mount a drive for database storage
echo "*******************************************************************************"
echo "Do you want to mount a separate drive for the database to use? (y/n)"
read -r mount_drive

if [[ "$mount_drive" =~ ^[Yy]$ ]]; then
    # Prompt the user to connect the drive and press enter when done
    echo "*******************************************************************************"
    echo "Please connect the drive you want to use for the database and press [Enter] when ready."
    read -r

    while true; do
        # Inform user that the drive will be formatted
        echo "*******************************************************************************"
        echo "WARNING: The selected drive will be formatted. All data on it will be lost.
        Please make sure you have selected the correct drive."
        
        # Display available drives
        lsblk

        # Prompt user for the target drive
        echo "*******************************************************************************"
        echo "Enter the drive to be mounted (e.g., /dev/sdb):"
        read -r target_drive

        # Verify the user input is a valid drive
        if lsblk | grep -q "^$(basename "$target_drive")"; then
            # Format the drive
            echo "Formatting the drive..."
            sudo mkfs.ext4 "$target_drive"

            # Create the mount point
            mount_point="/home/$USER/n8n-supabase-pi/mnt/database"
            echo "Creating mount point at $mount_point"
            mkdir -p "$mount_point"

            # Mount the drive
            echo "Mounting the drive..."
            sudo mount "$target_drive" "$mount_point"

            # Get the UUID of the drive
            drive_uuid=$(blkid -s UUID -o value "$target_drive")

            # Persist the mount in /etc/fstab
            echo "Persisting the mount in /etc/fstab"
            echo "UUID=$drive_uuid $mount_point ext4 defaults 0 2" | sudo tee -a /etc/fstab

            # Move existing volumes to the new mount point
            echo "Moving existing volumes to the mounted drive..."
            sudo mv /home/$USER/n8n-supabase-pi/volumes/* "$mount_point"

            # Update Docker Compose paths (assuming docker-compose.yml is in the same directory)
            echo "Updating Docker Compose volume paths to use the mounted drive..."
            sed -i 's|./volumes|./mnt/database|g' /home/$USER/n8n-supabase-pi/docker-compose.yml

            echo "Drive mounted and volumes moved successfully."
            break
        else
            echo "Invalid drive selected. Do you want to try again? (y/n)"
            read -r try_again
            if [[ ! "$try_again" =~ ^[Yy]$ ]]; then
                echo "Drive mount setup aborted by user."
                break
            fi
        fi
    done
else
    echo "Skipping drive mount setup."
fi

# Copy the .env.example file to .env for user configuration
cd /home/$USER/n8n-supabase-pi
cp .env.example .env

# Instructions for updating the .env file
echo "*******************************************************************************
Next, you need to update the .env file with the required environment variables. Use the following guides for reference:
- Supabase Guide: https://supabase.com/docs/guides/self-hosting/docker#securing-your-services/
- n8n Guide: https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#6-create-env-file

To save changes in nano, press CTRL + X, then Y to confirm saving, and Enter to finalize.
"

# Pause to ensure the user has read the instructions
read -p "*******************************************************************************
Press [Enter] to open the .env file for editing once you have read the instructions above."

# Open the .env file for the user to update with required environment variables
nano /home/$USER/n8n-supabase-pi/.env

# Secure the .env file by changing its permissions
chmod 600 /home/$USER/n8n-supabase-pi/.env

# Reboot the system
echo "Rebooting system to apply changes. After reboot, please manually run the part 2 setup script to continue."
sudo reboot
