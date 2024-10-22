#!/bin/bash

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
      echo "$prompt_message (y|n)"
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
  local type_name="$4"
  local prompt_message="$5"

  # Check if the configuration value was already decided
  eval config_value=\$$config_name
  eval drive_value=\$$drive_name
  if [ -z "$config_value" ] && [ -z "$drive_value" ]; then
    while true; do
      echo "$prompt_message (y|n)"
      read -r choice
      if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo "Please connect the drive you want to use and press [Enter] when ready."
        read -r

        # Inform user that the drive will be formatted
        echo "WARNING: The selected drive will be formatted. All data on it will be lost. Please make sure you select the correct drive."
        echo "*******************************************************************************"
        
        # Display available drives
        df -h

        # Prompt user for the target drive
        echo "*******************************************************************************"
        echo "Enter the filesystem name of the drive. Most external drives will be referenced under the '/dev/sd**' filesystem name:"
        read -r target_drive

        # Run blkid command to get information about the drive
        drive_info=$(sudo blkid "$target_drive")

        # Extract the UUID and TYPE using grep and awk
        drive_uuid=$(echo "$drive_info" | grep -oP 'UUID="\K[^"]+')
        drive_type=$(echo "$drive_info" | grep -oP 'TYPE="\K[^"]+')

        if [ -z "$drive_uuid" ]; then
          echo "ERROR: Unable to retrieve the UUID for the drive $target_drive."
          echo "This may be due to an issue with the drive itself or a misconfiguration."
          echo "Please make sure the drive is properly connected, unmounted, and not in use."
          echo "Please try again."
          continue
        fi

        echo "You selected: $target_drive"
        echo "Drive UUID: $drive_uuid"
        echo "Drive type: $drive_type"
        echo "Please confirm: Is this the correct drive? (y|n)"
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          # Write user's choice and drive to the config file
          write_choice "$config_name" "$choice"
          write_config "$drive_name" "$target_drive"
          write_config "$uuid_name" "$drive_uuid"
          write_config "$type_name" "$drive_type"
          break
        fi
      elif [[ "$choice" =~ ^[Nn]$ ]]; then
        # Write user's choice to the config file
        write_choice "$config_name" "$choice"
        break
      else
        echo "Invalid input. Please enter 'y' or 'n'."
        continue
      fi
    done
  else
    echo "$config_name has already been set to: $config_value"
    if [ "$config_value" == "True" ]; then
      echo "$drive_name has already been set to: $drive_value"
    fi
  fi
}