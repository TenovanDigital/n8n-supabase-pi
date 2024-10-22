#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Set the path to your .env file
ENV_FILE="/home/$USER/n8n-supabase-pi/.env"

# PostgreSQL container name (replace if your container has a different name)
CONTAINER_NAME="supabase-db"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$changed_postgres_password" == "True" ]; then
  echo "Postgres password has already been changed."
elif [ "$installed_docker" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^changed_postgres_password=/d' "$CONFIG_FILE"
  echo "changed_postgres_password=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't change Postgres password because Docker isn't installed. Install Docker and try again."
  exit 1
elif [ "$initialized_services" != "True" ]; then
  # Update the setup.conf file
  sed -i '/^changed_postgres_password=/d' "$CONFIG_FILE"
  echo "changed_postgres_password=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't change Postgres password because the $CONTAINER_NAME service hasn't been initialized. Initialize services and try again."
  exit 1
elif [ -z `docker compose ps -q $CONTAINER_NAME` ] || [ -z `docker ps -q --no-trunc | grep $(docker compose ps -q $CONTAINER_NAME)` ]; then
  # Update the setup.conf file
  sed -i '/^changed_postgres_password=/d' "$CONFIG_FILE"
  echo "changed_postgres_password=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't change Postgres password because the $CONTAINER_NAME service isn't running. Please check the $CONTAINER_NAME container and try again."
  exit 1
else
  # Get the new password from the .env file
  new_passwd=`grep POSTGRES_PASSWORD_NEW= "$ENV_FILE" | sed "s/.*=\(.*\)/\1/"`

  if [ -z $new_passwd ]; then
    # Update the setup.conf file
    sed -i '/^changed_postgres_password=/d' "$CONFIG_FILE"
    echo "changed_postgres_password=False" >> "$CONFIG_FILE"

    echo "ERROR: Can't change Postgres password because POSTGRES_PASSWORD_NEW has not been set in the environment variables. Please set that variable and try again."
    exit 1
  fi

  # Execute the SQL commands inside the Docker container
  docker exec -i $CONTAINER_NAME psql -h 127.0.0.1 -p 5432 -d postgres -U supabase_admin << EOT
    alter user anon with password '$new_passwd';
    alter user authenticated with password '$new_passwd';
    alter user authenticator with password '$new_passwd';
    alter user dashboard_user with password '$new_passwd';
    alter user pgbouncer with password '$new_passwd';
    alter user pgsodium_keyholder with password '$new_passwd';
    alter user pgsodium_keyiduser with password '$new_passwd';
    alter user pgsodium_keymaker with password '$new_passwd';
    alter user postgres with password '$new_passwd';
    alter user service_role with password '$new_passwd';
    alter user supabase_admin with password '$new_passwd';
    alter user supabase_auth_admin with password '$new_passwd';
    alter user supabase_functions_admin with password '$new_passwd';
    alter user supabase_read_only_user with password '$new_passwd';
    alter user supabase_replication_admin with password '$new_passwd';
    alter user supabase_storage_admin with password '$new_passwd';

    UPDATE _analytics.source_backends
    SET config = jsonb_set(config, '{url}', '"postgresql://supabase_admin:$new_passwd@db:5432/postgres"', 'false')
    WHERE type='postgres';
EOT

  # Check if the execution was successful
  if [ $? -eq 0 ]; then
    sed -i -e "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$new_passwd/g" "$ENV_FILE"
    sed -i "/^POSTGRES_PASSWORD_NEW=/d" "$ENV_FILE"

    # Update the setup.conf fi  le
    sed -i '/^changed_postgres_password=/d' "$CONFIG_FILE"
    echo "changed_postgres_password=True" >> "$CONFIG_FILE"

    echo "Postgres password changed successfully."
  else
    # Update the setup.conf file
    sed -i '/^changed_postgres_password=/d' "$CONFIG_FILE"
    echo "changed_postgres_password=False" >> "$CONFIG_FILE"

    echo "There was an error changing the Postgres password."
  fi
fi