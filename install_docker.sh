!/bin/bash
set -e
echo "Downloading docker install script from https://get.docker.com"
curl -fsSL https://get.docker.com | sh

# don't ever do this lol. It is actually dangerous
chmod +x install_docker.sh

# Installing without validating because I'm insane
echo "Executing Installation"
./install-docker.sh

# Verify Docker installation
echo "Verifying Docker installation..."
if command -v docker &> /dev/null; then
    echo "Docker installed successfully!"
    docker --version
else
    echo "Docker installation failed."
    exit 1
fi
# Clean up the installation script
echo "Cleaning up the Docker installation script..."
rm -f install-docker.sh






