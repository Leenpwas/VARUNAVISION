#!/bin/bash

# Quick start script for Orbbec Streamer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Orbbec Astra Pro Plus Streamer..."
echo ""

# Check if installed
if [ ! -f "$SCRIPT_DIR/streamer.py" ]; then
    echo "Error: streamer.py not found!"
    echo "Please run install.sh first:"
    echo "  sudo ./install.sh"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "Error: Virtual environment not found!"
    echo "Please run install.sh first:"
    echo "  sudo ./install.sh"
    exit 1
fi

# Check if service is running
if systemctl is-active --quiet orbbec-streamer 2>/dev/null; then
    echo "✓ Streamer is already running"
    echo ""
    echo "Access at:"
    IP=$(hostname -I | awk '{print $1}')
    echo "  http://$IP:5000"
    echo "  http://localhost:5000"
    echo ""
    echo "To stop:"
    echo "  sudo systemctl stop orbbec-streamer"
    echo ""
    echo "To view logs:"
    echo "  sudo journalctl -u orbbec-streamer -f"
else
    echo "Starting streamer service..."
    sudo systemctl start orbbec-streamer
    sleep 2

    if systemctl is-active --quiet orbbec-streamer; then
        echo "✓ Streamer started successfully!"
        echo ""
        IP=$(hostname -I | awk '{print $1}')
        echo "Access the web interface at:"
        echo "  http://$IP:5000"
        echo "  http://localhost:5000"
    else
        echo "✗ Failed to start streamer"
        echo ""
        echo "Check logs:"
        echo "  sudo journalctl -u orbbec-streamer -n 50"
    fi
fi
