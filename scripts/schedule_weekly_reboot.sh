#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# Schedule automated reboot every Sunday at 3 AM
if [ "$scheduled_weekly_reboot" == "True" ]; then
  echo "Weekly reboot already scheduled."
else
  (crontab -l 2>/dev/null; echo "0 3 * * 0 /sbin/reboot") | crontab -

  # Update the setup.conf file
  sed -i '/^scheduled_weekly_reboot=/d' "$CONFIG_FILE"
  echo "scheduled_weekly_reboot=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "Weekly reboot scheduled successfully."
fi