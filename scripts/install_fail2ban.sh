#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Initialize variables
fail2ban_bantime=""
fail2ban_maxretry=""

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ -z "$fail2ban_bantime" ]; then
  # Prompt the user for Fail2Ban configuration values
  while true; do
    read -p "Enter ban time in seconds for Fail2Ban (e.g., 1800 for 30 minutes, -1 for permanent): " time
    if [[ "$time" =~ ^-?[0-9]+$ ]]; then
      fail2ban_bantime="$time"
      break
    else
      echo "Invalid input. Please enter a numeric value for ban time."
    fi
  done
fi

if [ -z "$fail2ban_maxretry" ]; then
  while true; do
    read -p "Enter max retry attempts for Fail2Ban (e.g., 3): " retries
    if [[ "$retries" =~ ^[0-9]+$ ]]; then
      fail2ban_maxretry="$retries"
      break
    else
      echo "Invalid input. Please enter a numeric value for max retry attempts."
    fi
  done
fi

# Install Fail2Ban for security
sudo apt-get install -y fail2ban

# Copy default configuration to local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Insert Fail2Ban settings under [sshd] in jail.local
# See https://pimylifeup.com/raspberry-pi-fail2ban/
sudo awk -v bantime="$fail2ban_bantime" -v maxretry="$fail2ban_maxretry" '
  BEGIN {insert=0}
  /^\[sshd\]/ {print; print "enabled = true\nfilter = sshd\nbanaction = iptables-multiport\nbantime = " bantime "\nmaxretry = " maxretry; insert=1; next}
  {if (insert && /^[^\[]/) insert=0; if (!insert) print}
' /etc/fail2ban/jail.local | sudo tee /etc/fail2ban/jail.local.tmp && sudo mv /etc/fail2ban/jail.local.tmp /etc/fail2ban/jail.local

# Restart Fail2Ban service to apply the changes
sudo service fail2ban restart

# Update the setup.conf file
sed -i '/^installed_fail2ban=/d' "$CONFIG_FILE"
echo "installed_fail2ban=True" >> "$CONFIG_FILE"

# Confirmation message
echo "Fail2Ban has been installed and configured successfully."
