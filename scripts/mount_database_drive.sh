#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$mounted_database_drive" == "True" ]; then
  echo "Database Drive already mounted."
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
            sed -i "/^mount_database_drive=/d" "$CONFIG_FILE"
            sed -i "/^database_drive=/d" "$CONFIG_FILE"
            sed -i "/^database_drive_uuid=/d" "$CONFIG_FILE"
            sed -i "/^database_drive_type=/d" "$CONFIG_FILE"
            sed -i "/^format_database_drive=/d" "$CONFIG_FILE"
            sed -i "/^install_ntfs=/d" "$CONFIG_FILE"
            continue
          else
            break
          fi
        elif [ "$format_database_drive" == "False" ] && [ "$database_drive_type" == "exFAT" ]; then
          echo "Since the drive is using the 'exFAT' format, we will need to install the exFAT filesystem driver."
          prompt_choice "install_exfat" "Do you want to install the exFAT filesystem driver?"
          if [ "$install_exfat" == "False" ]; then
            echo "Without the exfat filesystem driver, this device won't be able to use this drive. Please try again."
            sed -i "/^mount_database_drive=/d" "$CONFIG_FILE"
            sed -i "/^database_drive=/d" "$CONFIG_FILE"
            sed -i "/^database_drive_uuid=/d" "$CONFIG_FILE"
            sed -i "/^database_drive_type=/d" "$CONFIG_FILE"
            sed -i "/^format_database_drive=/d" "$CONFIG_FILE"
            sed -i "/^install_exfat=/d" "$CONFIG_FILE"
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
      sudo mkfs.ext4 "$database_drive"
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
    sudo mkdir -p "$mount_point"

    # Give the user ownership of the mount point folder
    echo "Giving $USER ownership of $mount_point"
    sudo chown -R "$USER":"$USER" "$mount_point"

    # Persist the mount in /etc/fstab
    echo "Persisting the mount in /etc/fstab"
    echo "UUID=$database_drive_uuid $mount_point $database_drive_type defaults,auto,users,rw,nofail,noatime 0 0" | sudo tee -a /etc/fstab

    # If the device mounted automatically, we will need to unmount it temporarily.
    sudo umount "$database_drive"

    # Mount the drive using the /etc/fstab file
    echo "Mounting the drive..."
    sudo mount -a

    # Move existing volumes to the new mount point
    echo "Moving existing volumes to the mounted drive..."
    sudo mv /home/$USER/n8n-supabase-pi/volumes/* "$mount_point"

    # Update Docker Compose paths (assuming docker-compose.yml is in the same directory)
    echo "Updating Docker Compose volume paths to use the mounted drive..."
    sed -i 's|./volumes|./mnt/database|g' /home/$USER/n8n-supabase-pi/docker-compose.yml

    # Update the setup.conf file
    sed -i '/^mounted_database_drive=/d' "$CONFIG_FILE"
    echo "mounted_database_drive=True" >> "$CONFIG_FILE"

    # Confirmation message
    echo "Drive mounted and volumes moved successfully."
  else
    # Cancellation message
    echo "Cancelled mounting database drive."
  fi
fi