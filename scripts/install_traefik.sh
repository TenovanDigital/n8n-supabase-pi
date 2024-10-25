#!/bin/bash

# Define the configuration file path
CONFIG_FILE="/home/$USER/n8n-supabase-pi/setup.conf"

# Load setup configuration from the file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [ "$installed_traefik" == "True" ]; then
  echo "Traefik is already installed."
elif [ "$installed_docker" == "True" ]; then
  # Install htpasswd if not available
  if ! command -v htpasswd &> /dev/null
  then
      echo "htpasswd not found, installing apache2-utils..."
      sudo apt update && sudo apt install apache2-utils -y
  else
      echo "htpasswd is already installed."
  fi

  # Ensure the traefik network exists
  if ! sudo docker network ls | grep -q "traefik"; then
    echo "Traefik network not found. Creating traefik network..."
    sudo docker network create traefik
  fi

  # Install Traefik (reverse proxy)
  sudo docker pull traefik:3.1

  # Start up Traefik with necessary configuration
  sudo docker run -d \
    --name traefik \
    --restart always \
    -p 80:80 \
    -p 443:443 \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v traefik_data:/letsencrypt \
    --network traefik \
    -e TRAEFIK_USERNAME=${TRAEFIK_USERNAME} \
    -e TRAEFIK_PASSWORD_HASH=$(htpasswd -nbB ${TRAEFIK_USERNAME} ${TRAEFIK_PASSWORD}) \
    traefik:3.1 \
    --api.dashboard=true \
    --providers.docker=true \
    --providers.docker.exposedbydefault=false \
    --entrypoints.web.address=:80 \
    --entrypoints.web.http.redirections.entryPoint.to=websecure \
    --entrypoints.web.http.redirections.entrypoint.scheme=https \
    --entrypoints.websecure.address=:443 \
    --certificatesresolvers.myresolver.acme.tlschallenge=true \
    --certificatesresolvers.myresolver.acme.email=${SSL_EMAIL} \
    --certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json \
    -l "traefik.enable=true" \
    -l "traefik.http.routers.traefik.rule=Host(\`${SUBDOMAIN}.${DOMAIN_NAME}\`) && PathPrefix(\`/traefik\`)" \
    -l "traefik.http.routers.traefik.service=api@internal" \
    -l "traefik.http.routers.traefik.entrypoints=websecure" \
    -l "traefik.http.routers.traefik.tls=true" \
    -l "traefik.http.routers.traefik.tls.certresolver=myresolver" \
    -l "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_USERNAME}:${TRAEFIK_PASSWORD_HASH}" \
    -l "traefik.http.middlewares.traefik.headers.SSLRedirect=true" \
    -l "traefik.http.middlewares.traefik.headers.STSSeconds=315360000" \
    -l "traefik.http.middlewares.traefik.headers.browserXSSFilter=true" \
    -l "traefik.http.middlewares.traefik.headers.contentTypeNosniff=true" \
    -l "traefik.http.middlewares.traefik.headers.forceSTSHeader=true" \
    -l "traefik.http.middlewares.traefik.headers.SSLHost=${DOMAIN_NAME}" \
    -l "traefik.http.middlewares.traefik.headers.STSIncludeSubdomains=true" \
    -l "traefik.http.middlewares.traefik.headers.STSPreload=true" \
    -l "traefik.http.routers.traefik.middlewares=traefik-auth@docker,traefik@docker"

  # Update the setup.conf file
  sed -i '/^installed_traefik=/d' "$CONFIG_FILE"
  echo "installed_traefik=True" >> "$CONFIG_FILE"

  # Confirmation message
  echo "Traefik has been installed successfully."
else
  # Update the setup.conf file
  sed -i '/^installed_traefik=/d' "$CONFIG_FILE"
  echo "installed_traefik=False" >> "$CONFIG_FILE"

  echo "ERROR: Can't install Traefik because Docker isn't installed. Install Docker and try again."
  exit 1
fi
