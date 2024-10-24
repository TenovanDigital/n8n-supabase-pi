#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Define the docker-compose file path
DOCKER_COMPOSE_FILE="/home/$USER/n8n-supabase-pi/docker-compose.yml"

# Define Docker daemon config path
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"

# Function to clean up setup configuration
clean_up_config() {
  sed -i "/^mount_database_drive=/d" "$CONFIG_FILE"
  sed -i "/^database_drive=/d" "$CONFIG_FILE"
  sed -i "/^database_drive_uuid=/d" "$CONFIG_FILE"
  sed -i "/^database_drive_type=/d" "$CONFIG_FILE"
  sed -i "/^format_database_drive=/d" "$CONFIG_FILE"
  sed -i "/^install_ntfs=/d" "$CONFIG_FILE"
  sed -i "/^install_exfat=/d" "$CONFIG_FILE"
}

# Function to check if a command is available
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "ERROR: $1 is not installed. Please install it and try again."
    exit 1
  fi
}

# Check dependencies
check_command jq
check_command rsync
check_command docker

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$mounted_database_drive" == "True" ]; then
  echo "Database Drive already mounted."
elif ! command -v docker &> /dev/null; then
  echo "ERROR: Can't mount database drive for Docker because Docker isn't installed. Install Docker and try again."
  exit 1
else
  if [ -z "$database_drive" ]; then
    # Read in setup configuration functions
    . /home/$USER/n8n-supabase-pi/scripts/configure_setup_functions.sh

    # Prompt user for database drive mount configuration
    while true; do
      prompt_drive "mount_database_drive" "database_drive" "database_drive_uuid" "database_drive_type" "Do you want to mount a separate drive for the database to use?"
      if [ "$mount_database_drive" == "True" ]; then
        echo "It is recommended to format the database drive to the 'ext4' format prior to mounting it."
        echo "WARNING: This means ALL data on it will be erased!"
        prompt_choice "format_database_drive" "Do you want to format the drive?"
        if [ "$format_database_drive" == "False" ] && [ "$database_drive_type" == "ntfs" ]; then
          echo "Since the drive is using the 'ntfs' format, we will need to install the NTFS-3g driver."
          prompt_choice "install_ntfs" "Do you want to install the NTFS-3g driver?"
          if [ "$install_ntfs" == "False" ]; then
            echo "Without the NTFS-3g driver, this device won't be able to use this drive. Please try again."
            clean_up_config
            continue
          else
            break
          fi
        elif [ "$format_database_drive" == "False" ] && [ "$database_drive_type" == "exFAT" ]; then
          echo "Since the drive is using the 'exFAT' format, we will need to install the exFAT filesystem driver."
          prompt_choice "install_exfat" "Do you want to install the exFAT filesystem driver?"
          if [ "$install_exfat" == "False" ]; then
            echo "Without the exfat filesystem driver, this device won't be able to use this drive. Please try again."
            clean_up_config
            continue
          else
            break
          fi
        else
          break
        fi
      else
        break
      fi
    done
  fi

  # If user didn't cancel, then mount the drive
  if [ "$mount_database_drive" == "True" ]; then
    if [ "$format_database_drive" == "True" ]; then
      # Format the database drive
      echo "Formatting database drive..."
      if ! sudo mkfs.ext4 "$database_drive"; then
        echo "ERROR: Failed to format the drive."
        exit 1
      fi
      database_drive_type="ext4"
    elif [ "$install_ntfs" == "True" ]; then
      . /home/$USER/n8n-supabase-pi/scripts/install_ntfs.sh
    elif [ "$install_exfat" == "True" ]; then
      . /home/$USER/n8n-supabase-pi/scripts/install_exfat.sh
    fi

    # Guide for mounting a drive: https://pimylifeup.com/raspberry-pi-mount-usb-drive/

    # Create the mount point
    mount_point="/home/$USER/n8n-supabase-pi/mnt/database"
    echo "Creating mount point at $mount_point"
    if ! sudo mkdir -p "$mount_point"; then
      echo "ERROR: Failed to create mount point."
      exit 1
    fi

    # Give the user ownership of the mount point folder and set Docker permissions
    echo "Giving $USER ownership of $mount_point and setting permissions for Docker..."
    if ! sudo chown -R "$USER":"$USER" "$mount_point"; then
      echo "ERROR: Failed to set ownership and permissions for mount point."
      exit 1
    fi

    # Persist the mount in /etc/fstab
    echo "Persisting the mount in /etc/fstab"
    if ! echo "UUID=$database_drive_uuid $mount_point $database_drive_type defaults,auto,users,rw,nofail,noatime 0 0" | sudo tee -a /etc/fstab; then
      echo "ERROR: Failed to persist the mount in /etc/fstab."
      exit 1
    fi

    # If the device mounted automatically, we will need to unmount it temporarily.
    if ! sudo umount "$database_drive"; then
      echo "ERROR: Failed to unmount the drive."
      exit 1
    fi

    # Mount the drive using the /etc/fstab file
    echo "Mounting the drive..."
    if ! sudo mount -a; then
      echo "ERROR: Failed to mount the drive."
      exit 1
    fi

    # Move the volumes folder to the new mount point
    echo "Moving the volumes folder to the mounted drive..."
    if ! sudo mv /home/$USER/n8n-supabase-pi/volumes "$mount_point/volumes"; then
      echo "ERROR: Failed to move volumes folder."
      exit 1
    fi

    # Update Docker Compose paths (assuming docker-compose.yml is in the same directory)
    echo "Updating Docker Compose volume mount paths..."
    if ! sed -i 's|./volumes|./mnt/database/volumes|g' "$DOCKER_COMPOSE_FILE"; then
      echo "ERROR: Failed to update Docker Compose paths."
      exit 1
    fi

    # Update Docker data location
    echo "Updating Docker data location..."
    if [[ -f "$DOCKER_DAEMON_CONFIG" ]]; then
      echo "Updating existing Docker daemon configuration..."
      if ! sudo jq '."data-root" = "'"$mount_point"'/docker"' "$DOCKER_DAEMON_CONFIG" | sudo tee "$DOCKER_DAEMON_CONFIG.tmp"; then
        echo "ERROR: Failed to update Docker daemon configuration."
        exit 1
      fi
      sudo mv "$DOCKER_DAEMON_CONFIG.tmp" "$DOCKER_DAEMON_CONFIG"
    else
      echo "Creating Docker daemon configuration file..."
      echo '{ "data-root": "'"$mount_point"'/docker" }' | sudo tee "$DOCKER_DAEMON_CONFIG"
    fi

    # Copy Docker data to new location
    echo "Copying Docker data to new location..."
    if ! sudo rsync -aP /var/lib/docker/ "$mount_point/docker"; then
      echo "ERROR: Failed to copy Docker data."
      exit 1
    fi

    # Remove old Docker data directory
    echo "Removing old Docker data directory..."
    if ! sudo rm -rf /var/lib/docker; then
      echo "ERROR: Failed to remove old Docker data directory."
      exit 1
    fi

    # Update the setup.conf file
    sed -i '/^mounted_database_drive=/d' "$CONFIG_FILE"
    echo "mounted_database_drive=True" >> "$CONFIG_FILE"

    # Confirmation message
    echo "Drive mounted and volumes moved successfully. Docker data location updated."
  else
    # Cancellation message
    echo "Cancelled mounting database drive."
  fi
fi
