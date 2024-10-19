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

# Function to write user choice to the configuration file
write_choice() {
  local service_name="$1"
  local choice="$2"

  sed -i "/^$service_name=/d" "$CONFIG_FILE"

  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "$service_name=True" >> "$CONFIG_FILE"
  else
    echo "$service_name=False" >> "$CONFIG_FILE"
  fi

  # Re-read the config file to get the latest values
  source "$CONFIG_FILE"
}

# Function to write service config to the configuration file
write_config() {
  local service_name="$1"
  local config="$2"

  sed -i "/^$service_name=/d" "$CONFIG_FILE"
  echo "$service_name=$config" >> "$CONFIG_FILE"

  # # Re-read the config file to get the latest values
  # source "$CONFIG_FILE"
}

# Function to prompt the user for their choice if not already decided
prompt_choice() {
  local service_name="$1"
  local prompt_message="$2"

  # Check if the service was already decided
  eval choice=\$$service_name
  if [ -z "$choice" ]; then
    while true; do
      echo "$prompt_message (y/n)"
      read -r choice
      if [[ "$choice" =~ ^[YyNn]$ ]]; then
        break
      else
        echo "Invalid input. Please enter 'y' or 'n'."
      fi
    done
    # Write the user's choice to the config file
    write_choice "$service_name" "$choice"
  else
    echo "$service_name has already been set to: $choice"
  fi
}

# Function to prompt for additional configuration if required
prompt_numerical_config() {
  local config_name="$1"
  local prompt_message="$2"

  # Check if the configuration value was already decided
  eval config_value=\$$config_name
  if [ -z "$config_value" ]; then
    while true; do
      echo "$prompt_message"
      read -r config_value
      if [[ "$config_value" =~ ^-?[0-9]+$ ]]; then
        break
      else
        echo "Invalid input. Please enter a numeric value."
      fi
    done
    # Write the configuration value to the config file
    write_config "$config_name" "$config_value"
  else
    echo "$config_name has already been set to: $config_value"
  fi
}

# Function to prompt for additional string configuration if required
prompt_string_config() {
  local config_name="$1"
  local prompt_message="$2"

  # Check if the configuration value was already decided
  eval config_value=\$$config_name
  if [ -z "$config_value" ]; then
    while true; do
      echo "$prompt_message"
      read -r config_value
      if [ -n "$config_value" ]; then
        break
      else
        echo "Invalid input. Please enter a non-empty value."
      fi
    done
    # Write the configuration value to the config file
    write_config "$config_name" "$config_value"
  else
    echo "$config_name has already been set to: $config_value"
  fi
}

prompt_drive() {
  local config_name="$1"
  local drive_name="$2"
  local uuid_name="$3"
  local prompt_message="$4"

  # Check if the configuration value was already decided
  eval config_value=\$$config_name
  eval drive_value=\$$drive_name
  if [ -z "$config_value" $$ -z "$drive_value"]; then
    while true; do
      echo "$prompt_message (y/n)"
      read -r choice
      if [[ "$choice" =~ ^[YyNn]$ ]]; then
        echo "Please connect the drive you want to use and press [Enter] when ready."
        read -r

        # Inform user that the drive will be formatted
        echo "WARNING: The selected drive will be formatted. All data on it will be lost. Please make sure you select the correct drive."
        echo "*******************************************************************************"
        
        # Display available drives
        lsblk

        # Prompt user for the target drive
        echo "*******************************************************************************"
        echo "Enter the name of the drive without the leading '/dev/' (e.g., sba, sdb, etc.):"
        read -r name

        # Add '/dev/' prefix to the user input
        target_drive="/dev/$name"

        # Verify the user input is a valid drive
        if lsblk | grep -q "$name"; then
          # Get the UUID of the drive
          drive_uuid=$(blkid -s UUID -o value "$target_drive")

          if [ -z "$drive_uuid" ]; then
            echo "ERROR: Unable to retrieve the UUID for the drive $target_drive."
            echo "This may be due to an issue with the drive itself or a misconfiguration."
            echo "Please make sure the drive is properly connected, unmounted, and not in use."
            echo "Please try again."
            continue
          fi

          echo "You selected: $target_drive"
          echo "Drive UUID: $drive_uuid"
          echo "WARNING: This will format $target_drive. All data on it will be erased!"
          echo "Please confirm: Is this the correct drive? (y/n)"
          read -r confirm
          if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Write user's choice and drive to the config file
            write_choice "$service_name" "$choice"
            write_config "$drive_name" "$target_drive"
            write_config "$uuid_name" "$drive_uuid"
            break
          fi
        else
          echo "Invalid drive selected. Please try again."
          continue
        fi
      else
        echo "Invalid input. Please enter 'y' or 'n'."
        continue
      fi

      if [[ "$choice" =~ ^[Nn]$ ]]; then
        # Write user's choice to the config file
        write_choice "$service_name" "$choice"
        break
      fi
    done
  else
    echo "$config_name has already been set to: $config_value"
    if [ "$config_value" == "True" ]; then
      echo "$drive_name has already been set to: $drive_value"
    fi
  fi
}

# Function to prompt for all services
prompt_all_services() {
  # Prompt for services and configurations
  prompt_choice "install_argon_one" "Install Argon One PI 4 V2 Power Button & Fan Control?"
  prompt_choice "install_rpi_connect" "Install Raspberry Pi Connect?"
  prompt_choice "install_fail2ban" "Do you want to install Fail2Ban for security?"
  if [ "$install_fail2ban" == "True" ]; then
    prompt_numerical_config "fail2ban_bantime" "Enter ban time in seconds for Fail2Ban (e.g., 1800 for 30 minutes, -1 for permanent):"
    prompt_numerical_config "fail2ban_maxretry" "Enter max retry attempts for Fail2Ban (e.g., 3):"
  fi
  prompt_choice "install_ufw" "Do you want to install UFW (Uncomplicated Firewall) for security?"
  prompt_drive "mount_database_drive" "database_drive" "database_drive_uuid" "Do you want to mount a separate drive for the database to use?"
  prompt_choice "install_portainer" "Do you want to install Portainer for managing Docker containers?"

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
    break
  elif [[ "$confirm" =~ ^[Nn]$ ]]; then
    # Clear the config file and prompt user again
    > "$CONFIG_FILE"
    echo "Configuration file cleared. Restarting the setup..."
    prompt_all_services
    break
  else
    echo "Invalid input. Please enter 'y' or 'n'."
  fi
done

# Update the setup.conf file
sed -i '/^configured_setup=/d' "$CONFIG_FILE"
echo "configured_setup=True" >> "$CONFIG_FILE"