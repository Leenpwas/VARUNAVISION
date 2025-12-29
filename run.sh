#!/bin/bash

# Direct run script for Orbbec Streamer (without systemd)
# Use this for testing or when you don't want to use systemd

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Orbbec Astra Pro Plus Streamer (Direct Mode)..."
echo ""

# Check if files exist
if [ ! -f "$SCRIPT_DIR/streamer.py" ]; then
    echo "Error: streamer.py not found!"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "Error: Virtual environment not found!"
    echo "Please run install.sh first"
    exit 1
fi

# Activate virtual environment and run
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/venv/bin/activate"

echo "Using Python: $(which python)"
echo "Using Flask: $(python -c 'import flask; print(flask.__version__)')"
echo ""

# Get IP address
IP=$(hostname -I | awk '{print $1}')

echo "=========================================="
echo "Streamer Starting..."
echo "=========================================="
echo ""
echo "Access the web interface at:"
echo "  http://$IP:5000"
echo "  http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "=========================================="
echo ""

# Run the streamer
python "$SCRIPT_DIR/streamer.py"
