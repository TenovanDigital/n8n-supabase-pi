# n8n-supabase-pi

## Overview

n8n-supabase-pi is a complete setup for deploying n8n and Supabase on a Raspberry Pi, creating a powerful automation and data platform. This repository contains scripts and Docker Compose files that help automate the setup and configuration process, turning your Raspberry Pi into a self-hosted automation powerhouse.

The setup includes:

- n8n: An open-source workflow automation tool.
- Supabase: A backend-as-a-service for managing databases and APIs.
- Traefik: An edge router providing automatic SSL certificates for secure access.
- Raspberry Pi Connect: Allows you to connect to your Raspberry Pi from anywhere.
- Additional services for security and management (e.g., Portainer, Fail2Ban, UFW).

## Features

- **Automated Deployment**: Bash scripts to automate the setup of n8n, Supabase, and required tools on Raspberry Pi.
- **Security Tools**: Fail2Ban, UFW, and secure environment variable management for robust security.
- **Docker Orchestration**: Uses Docker Compose for container orchestration, simplifying service management.
- **Portainer for Docker Management**: Web-based interface for managing Docker containers on your Raspberry Pi.
- **Remote Access**: Raspberry Pi Connect to allow connecting to your Raspberry Pi from anywhere.
- **Scheduled Reboot**: The Raspberry Pi is set up to reboot every Sunday at 3 AM to ensure optimal performance.

## Prerequisites

- Raspberry Pi 4 with a 64-bit Debian-based OS (Bookworm or later) installed:
  - **64-bit Requirement**: A 64-bit OS is required for n8n compatibility.
  - **OS Version Requirement**: Debian-based OS version must be "Bookworm" or later for Raspberry Pi Connect compatibility.
- Basic knowledge of SSH and Linux commands.

## Installation

1. **Install Git**:

   ```sh
   sudo apt-get update
   sudo apt-get install git -y
   ```

2. **Clone the Repository**:

   ```sh
   git clone https://github.com/yourusername/n8n-supabase-pi.git
   cd n8n-supabase-pi
   ```

3. **Run the Setup Script (Part 1)**:
   Execute the first setup script to install all necessary dependencies and reboot the Raspberry Pi:

   ```sh
   ./setup_part1.sh
   ```

   The system will reboot after part 1 to apply changes.

4. **Run the Setup Script (Part 2)**:
   After reboot, manually run the second setup script to complete the installation:

   ```sh
   ./setup_part2.sh
   ```

   Follow the prompts to:

   - Set up **Raspberry Pi Connect**: Create a Raspberry Pi ID to link the device by visiting [Raspberry Pi ID](https://id.raspberrypi.com/).
   - Set up **Portainer**: Follow the setup instructions in [this guide](https://pimylifeup.com/raspberry-pi-portainer/).
   - Configure **environment variables**: Update the `.env` file using the following resources:
     - [Supabase Guide](https://supabase.com/docs/guides/self-hosting/docker#securing-your-services/)
     - [n8n Guide](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#6-create-env-file)
   - Configure **DNS**: Set up DNS using [this guide](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#4-dns-setup)

## Accessing Services

- **n8n**: Once the setup is complete, n8n can be accessed at `http://<your-ip>:5678` or at the configured subdomain and domain.
- **Portainer**: For Docker management, access Portainer at `http://<your-ip>:9000`.

## Troubleshooting

- **Docker Not Running**: Ensure the Docker service is running with `sudo systemctl status docker`. If not, restart it with `sudo systemctl restart docker`.
- **Portainer Setup Issues**: Make sure Portainer is accessible at port 9000. If not, verify your firewall settings with `sudo ufw status`.
- **Environment Variables**: Double-check the `.env` file for any missing or incorrect variables, which could cause services to fail.

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request if you have suggestions or improvements.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
