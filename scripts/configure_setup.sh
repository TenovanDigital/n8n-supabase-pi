#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Create the config file if it does not exist, otherwise read existing choices
if [ ! -f "$CONFIG_FILE" ]; then
  touch "$CONFIG_FILE"
  echo "Configuration file created: $CONFIG_FILE"
else
  echo "Configuration file exists: $CONFIG_FILE"
  echo "Loading existing choices..."
  source "$CONFIG_FILE"
fi

if [ "$configured_setup" == "True" ]; then
  echo "Setup has already been configured."
else
  # Read in setup configuration functions
  . /home/$USER/n8n-supabase-pi/scripts/configure_setup_functions.sh

  # Function to prompt for all services
  prompt_all_services() {
    # Prompt for services and configurations
    prompt_choice "install_argon_one" "Do you want to install Argon One PI 4 V2 Power Button & Fan Control?"
    prompt_choice "install_rpi_connect" "Do you want to install Raspberry Pi Connect?"
    prompt_choice "install_portainer" "Do you want to install Portainer for managing Docker containers?"
    prompt_choice "install_fail2ban" "Do you want to install Fail2Ban for security?"
    if [ "$install_fail2ban" == "True" ]; then
      prompt_numerical_config "fail2ban_bantime" "Enter ban time in seconds for Fail2Ban (e.g., 1800 for 30 minutes, -1 for permanent):"
      prompt_numerical_config "fail2ban_maxretry" "Enter max retry attempts for Fail2Ban (e.g., 3):"
    fi
    prompt_choice "install_ufw" "Do you want to install UFW (Uncomplicated Firewall) for security?"
    while true; do
      prompt_drive "mount_database_drive" "database_drive" "database_drive_uuid" "database_drive_type" "Do you want to mount a separate drive for the database to use?"
      if [ "$mount_database_drive" == "True" ]; then
        echo "It is recommended to format the database drive to the 'ext4' format prior to mounting it."
        echo "WARNING: This means ALL data on it will be erased!"
        prompt_choice "format_database_drive" "Do you want to format the drive?"
        if [ "$format_database_drive" == "False" ]; then
          echo "Without formatting this drive, this device won't be able to use it. Please try again."
          clean_up_drive_config
          continue
        else
        else
          break
        fi
      else
        break
      fi
    done

    # Display all user choices
    echo "*******************************************************************************"
    echo "Final choices:"
    cat "$CONFIG_FILE"
    echo "*******************************************************************************"
  }

  # Prompt for services to install if not already decided
  prompt_all_services

  # Confirm choices
  while true; do
    echo "Are these choices correct? (y/n)"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      # Proceed with the setup since choices are confirmed
      echo "Proceeding with setup..."
      break
    elif [[ "$confirm" =~ ^[Nn]$ ]]; then
      # Clear the config file
      > "$CONFIG_FILE"

      # Restart the script
      echo "Configuration file cleared. Restarting the setup..."
      exec "$0"
    else
      echo "Invalid input. Please enter 'y' or 'n'."
    fi
  done

  # Update the setup.conf file
  sed -i '/^configured_setup=/d' "$CONFIG_FILE"
  echo "configured_setup=True" >> "$CONFIG_FILE"
fi