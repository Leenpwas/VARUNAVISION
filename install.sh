#!/bin/bash

# Orbbec Astra Pro Plus Streamer - One Click Install
# Compatible with Ubuntu 24.04 on Raspberry Pi
set -e

echo "=========================================="
echo "Orbbec Astra Pro Plus Streamer Installer"
echo "=========================================="
echo ""

# Get the real user's home directory (not root's)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo ~"$SUDO_USER")
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

echo "Installing for user: $REAL_USER"
echo "Home directory: $REAL_HOME"
echo ""

# Detect system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Detected OS: $PRETTY_NAME"
fi

if [ -f /proc/device-tree/model ]; then
    MODEL=$(cat /proc/device-tree/model | tr -d '\0')
    echo "Hardware: $MODEL"
else
    echo "Hardware: Generic Linux System"
fi

# Detect architecture
ARCH=$(uname -m)
echo "Architecture: $ARCH"

# Update system
echo "[1/7] Updating system packages..."
sudo apt update

# Install system dependencies
echo "[2/7] Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-opencv \
    v4l-utils \
    git \
    wget \
    curl \
    libopencv-dev \
    python3-numpy \
    libusb-1.0-0-dev \
    build-essential

# Install OpenNI2 from Ubuntu repos (if available)
echo "[3/7] Installing OpenNI2..."
sudo apt install -y libopenni2-0 libopenni2-dev 2>/dev/null || {
    echo "OpenNI2 not in Ubuntu repos, will use fallback mode"
}

# Install Python packages - use pip with user flag or venv
echo "[4/7] Installing Python packages..."

# For Ubuntu 24.04 (PEP 668), create a virtual environment
VENV_DIR="$REAL_HOME/orbbec-streamer/venv"

echo "Creating Python virtual environment at $VENV_DIR"
python3 -m venv "$VENV_DIR"

# Activate and install packages
source "$VENV_DIR/bin/activate"
echo "Installing Python packages in virtual environment..."
pip install --upgrade pip
pip install \
    opencv-python \
    numpy \
    flask \
    flask-cors \
    pillow

echo "✓ Python packages installed successfully"

# Setup Orbbec SDK/OpenNI2
echo "[5/7] Setting up Orbbec camera support..."
mkdir -p "$REAL_HOME/Orbbec"
cd "$REAL_HOME/Orbbec"

# Try to download Orbbec SDK for Linux ARM64
if [ "$ARCH" = "aarch64" ]; then
    echo "Attempting to download Orbbec SDK for ARM64..."

    # Try Orbbec's official SDK
    wget -O orbbec-sdk.tar.gz "https://orbbec3d.com/develop/AstraSDK/archive/Linux/AstraSDK-v2.0.18-8f8c91b-Linux-aarch64.tar.gz" 2>/dev/null || {
        echo "Note: Orbbec SDK download not available"
        echo "The streamer will use standard USB camera fallback mode"
    }

    # Extract if downloaded
    if [ -f orbbec-sdk.tar.gz ]; then
        tar -xzf orbbec-sdk.tar.gz || true
    fi
fi

# Create udev rules for Orbbec camera
echo "[6/7] Setting up udev rules for Orbbec camera..."
sudo bash -c 'cat > /etc/udev/rules.d/56-orbbec.rules << EOF
# Orbbec Astra cameras
SUBSYSTEM=="usb", ATTR{idVendor}=="2bc5", MODE="0666"
SUBSYSTEM=="usb_device", ATTR{idVendor}=="2bc5", MODE="0666"
KERNEL=="video*", ATTR{idVendor}=="2bc5", MODE="0666"
EOF'

sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to video group for camera access
echo "Adding user to video group..."
sudo usermod -aG video "$REAL_USER" 2>/dev/null || true

# Create directory structure
echo "[7/7] Setting up streamer directory..."
STREAMER_DIR="$REAL_HOME/orbbec-streamer"
mkdir -p "$STREAMER_DIR/templates"
mkdir -p "$STREAMER_DIR/logs"

# Copy files if not already in place
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$SCRIPT_DIR" != "$STREAMER_DIR" ]; then
    echo "Copying files to $STREAMER_DIR..."
    cp "$SCRIPT_DIR"/*.py "$STREAMER_DIR/" 2>/dev/null || true
    cp "$SCRIPT_DIR"/templates/*.html "$STREAMER_DIR/templates/" 2>/dev/null || true
    cp "$SCRIPT_DIR"/start.sh "$STREAMER_DIR/" 2>/dev/null || true
    cp "$SCRIPT_DIR"/run.sh "$STREAMER_DIR/" 2>/dev/null || true
fi

# Install systemd service
echo "Installing systemd service..."
sudo bash -c "cat > /etc/systemd/system/orbbec-streamer.service << EOF
[Unit]
Description=Orbbec Astra Pro Plus Streamer
After=network.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$STREAMER_DIR
Environment=PYTHONUNBUFFERED=1
ExecStart=$STREAMER_DIR/venv/bin/python $STREAMER_DIR/streamer.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable orbbec-streamer.service

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "To start the streamer:"
echo "  sudo systemctl start orbbec-streamer"
echo ""
echo "To enable auto-start on boot:"
echo "  sudo systemctl enable orbbec-streamer"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u orbbec-streamer -f"
echo ""
echo "Access the web interface at:"
echo "  http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "=========================================="
