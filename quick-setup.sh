#!/bin/bash

# One-Command Setup for Orbbec Astra Pro Plus Streamer
# This script clones the repo and installs everything

set -e

echo "=========================================="
echo "Orbbec Streamer - One Command Setup"
echo "=========================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    sudo apt update
    sudo apt install -y git
fi

# Clone the repository
if [ -d "$HOME/VARUNAVISION" ]; then
    echo "Repository already exists, pulling latest..."
    cd "$HOME/VARUNAVISION"
    git pull
else
    echo "Cloning repository..."
    git clone git@github.com:Leenpwas/VARUNAVISION.git "$HOME/VARUNAVISION"
    cd "$HOME/VARUNAVISION"
fi

# Run the installer
echo ""
echo "Running installer..."
sudo ./install.sh

# Start the service
echo ""
echo "Starting streamer service..."
sudo systemctl start orbbec-streamer

# Get IP address
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Access the web interface at:"
echo "  http://$IP:5000"
echo ""
echo "To check status:"
echo "  sudo systemctl status orbbec-streamer"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u orbbec-streamer -f"
echo ""
echo "=========================================="
