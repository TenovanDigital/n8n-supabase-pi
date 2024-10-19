# n8n-supabase-pi

## Overview

n8n-supabase-pi is a complete setup for deploying n8n and Supabase on a Raspberry Pi, creating a powerful automation and data platform. This repository contains scripts and Docker Compose files that help automate the setup and configuration process, turning your Raspberry Pi into a self-hosted automation powerhouse.

This is still being tested, so use at your own risk.

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

- Raspberry Pi 4 with a 64-bit Raspberry Pi OS (Bookworm or later) installed:
  - **64-bit Requirement**: A 64-bit OS is required for n8n compatibility.
  - **OS Version Requirement**: Raspberry Pi OS version must be "Bookworm" or later for Raspberry Pi Connect compatibility.
- Basic knowledge of SSH and Linux commands.

## Recommendations

- [Argon ONE M.2 Case for Raspberry Pi 4](https://argon40.com/products/argon-one-m-2-case-for-raspberry-pi-4?srsltid=AfmBOorKZf-7TrKTBIB6T3fUDcw28vrTysTmWWpj0O1wv9lGfZ5RDPMF)
- Storage Drive for the database (I will be using a M.2 SSD in the case)

## Installation

1. **Install Git**:

   ```sh
   sudo apt-get update
   sudo apt-get install git -y
   ```

2. **Clone the Repository**:

   ```sh
   git clone https://github.com/TenovanDigital/n8n-supabase-pi.git
   cd n8n-supabase-pi
   ```

3. **Run the Setup Script (Part 1)**:
   Execute the first setup script to install all necessary dependencies and reboot the Raspberry Pi:

   ```sh
   chmod +x setup_part1.sh
   ./setup_part1.sh
   ```

   Follow the prompts to:

   - Install **ArgonOne Case Script** (Optional)
   - Configure **Fail2Ban** (Optional): Configure Fail2Ban following these instructions:
      - [Fail2Ban Guide](https://pimylifeup.com/raspberry-pi-fail2ban/)
   - Mount **Database Drive** (Optional)
   - Configure **Environment Variables**: Update the `.env` file using the following resources:
      - [Supabase Guide](https://supabase.com/docs/guides/self-hosting/docker#securing-your-services/)
      - [n8n Guide](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#6-create-env-file)

   The system will reboot after part 1 to apply changes.

4. **Run the Setup Script (Part 2)**:
   After reboot, manually run the second setup script to complete the installation:

   ```sh
   chmod +x setup_part2.sh
   ./setup_part2.sh
   ```

   Follow the prompts to:

   - Set up **Raspberry Pi Connect**: Create a Raspberry Pi ID to link the device by visiting [Raspberry Pi ID](https://id.raspberrypi.com/).
   - Set up **Portainer**: Follow the setup instructions in [this guide](https://pimylifeup.com/raspberry-pi-portainer/).
   - Configure **DNS**: Set up DNS using [this guide](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/#4-dns-setup)
   - Configure **Port Forwarding**: You also need to configure port forwarding on your router. Still working out which ports to forward, so stay tuned!

## Accessing Services

- **n8n**: Once the setup is complete, n8n can be accessed at `http://<your-ip>:5678` or at the configured subdomain and domain.
- **Supabase**: For database management, access Supabase at `http://<your-ip>:8000`.
- **Portainer**: For Docker management, access Portainer at `http://<your-ip>:9000`.

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request if you have suggestions or improvements.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
