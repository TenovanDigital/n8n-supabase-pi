#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

mount_database_drive() {
  local drive="$1"
  local uuid="$2"

  # Format the database drive
  echo "Formatting database drive..."
  sudo mkfs.ext4 "$drive"

  # Create the mount point
  mount_point="/home/$USER/n8n-supabase-pi/mnt/database"
  echo "Creating mount point at $mount_point"
  mkdir -p "$mount_point"

  # Mount the drive
  echo "Mounting the drive..."
  sudo mount "$drive" "$mount_point"

  # Persist the mount in /etc/fstab
  echo "Persisting the mount in /etc/fstab"
  echo "UUID=$uuid $mount_point ext4 defaults 0 2" | sudo tee -a /etc/fstab

  # Move existing volumes to the new mount point
  echo "Moving existing volumes to the mounted drive..."
  sudo mv /home/$USER/n8n-supabase-pi/volumes/* "$mount_point"

  # Update Docker Compose paths (assuming docker-compose.yml is in the same directory)
  echo "Updating Docker Compose volume paths to use the mounted drive..."
  sed -i 's|./volumes|./mnt/database|g' /home/$USER/n8n-supabase-pi/docker-compose.yml

  echo "Drive mounted and volumes moved successfully."
}

if [ -z "$database_drive" ]; then
  while true; do
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
        mount_database_drive "$target_drive" "$drive_uuid"
        break
      fi
    else
      echo "Invalid drive selected. Please try again."
      continue
    fi
  done
else
  mount_database_drive "$database_drive" "$database_drive_uuid"
fi

# Update the setup.conf file
sed -i '/^mounted_database_drive=/d' "$CONFIG_FILE"
echo "mounted_database_drive=True" >> "$CONFIG_FILE"