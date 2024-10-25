#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Set the path to your .env file
ENV_FILE="/home/$USER/n8n-supabase-pi/.env"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$configured_env" == "True" ]; then
  echo "Environment variables have already been configured."
else
  # Copy the .env.example file to .env for user configuration
  cp /home/$USER/n8n-supabase-pi/.env.example $ENV_FILE

  # Function to prompt for a value and insert it into the .env file
  prompt_env_var() {
    local var_name="$1"
    local instructions="$2"
    local prompt_message="$3"

    echo "$var_name: $instructions"

    # Check if the variable already exists in the .env file
    if grep -q "^${var_name}=" "$ENV_FILE"; then
      # Extract the existing value if needed
      current_value=$(grep "^${var_name}=" "$ENV_FILE" | cut -d '=' -f2-)
      read -p "${prompt_message} (current: ${current_value}): " user_input

      # Use the current value if user_input is empty
      if [ -z "$user_input" ]; then
        user_input="$current_value"
      fi

      # Escape special characters in the user input
      escaped_value=$(printf '%s\n' "$user_input" | sed -e 's/[\/&]/\\&/g')

      # Update the variable in the .env file
      sed -i "s|^${var_name}=.*|${var_name}=${escaped_value}|" "$ENV_FILE"
    else
      # Prompt the user for a new value if the variable doesn't exist
      read -p "${prompt_message}: " user_input

      # Add the variable to the .env file
      echo "${var_name}=${user_input}" >> "$ENV_FILE"
    fi
  }

  # Start message
  echo "Now we will configure the environment variables..."

  # Prompt the user for the required environment variables
  # Reference guides:
  # - Supabase: https://supabase.com/docs/guides/self-hosting/docker#securing-your-services/
  # - n8n: https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#6-create-env-file
  echo ""
  echo "[Supabase]"
  prompt_env_var "POSTGRES_PASSWORD" "Should be at least 32 characters long with no special characters" "Enter the PostgreSQL password"
  prompt_env_var "JWT_SECRET" "Should be at least 32 characters long with no special characters. Hold onto this one to generate next secrets." "Enter the JWT secret"
  prompt_env_var "ANON_KEY" "Use the JWT_SECRET to generate this anon key using the form here: https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys" "Enter the anonymous key"
  prompt_env_var "SERVICE_KEY" "Use the JWT_SECRET to generate this service key using the form here: https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys" "Enter the service key"
  prompt_env_var "SUPABASE_USERNAME" "Credential for you to log into your Supabase dashboard" "Enter username"
  prompt_env_var "SUPABASE_PASSWORD" "Credential for you to log into your Supabase dashboard" "Enter password"
  echo ""
  echo "[n8n]"
  prompt_env_var "POSTGRES_HOST" "Database host n8n will use" "Enter database host or press [Enter] to keep default"
  prompt_env_var "POSTGRES_PORT" "Port n8n will use for database access" "Enter port or press [Enter] to keep default"
  prompt_env_var "N8N_PORT" "Port to access n8n" "Enter port or press [Enter] to keep default"
  prompt_env_var "N8N_SECURE_COOKIE" "Require https connection to use n8n" "Enter 'true' or 'false' or press [Enter] to keep default"
  echo ""
  echo "[Traefik]"
  prompt_env_var "DOMAIN_NAME" "The top level domain to serve n8n from" "Enter your domain name"
  prompt_env_var "SUBDOMAIN" "The subdomain to serve n8n from" "Enter the subdomain"
  prompt_env_var "SSL_EMAIL" "The email address to use for the SSL certificate creation" "Enter the email address"
  prompt_env_var "GENERIC_TIMEZONE" "Optional timezone to set which gets used by Cron-Node by default" "Enter timezone"
  prompt_env_var "TRAEFIK_USERNAME" "Credential for you to log into your Traefik dashboard" "Enter username"
  prompt_env_var "TRAEFIK_PASSWORD" "Credential for you to log into your Traefik dashboard" "Enter password"

  # Confirmation message
  echo ""
  echo ".env file has been updated successfully."
  echo ""
  echo "You can edit other environment variables by using nano."

  # Secure the .env file by changing its permissions
  chmod 600 /home/$USER/n8n-supabase-pi/.env

  # Update the setup.conf file
  sed -i '/^configured_env=/d' "$CONFIG_FILE"
  echo "configured_env=True" >> "$CONFIG_FILE"
fi