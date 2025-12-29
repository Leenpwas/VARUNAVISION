# Orbbec Astra Pro Plus Streamer

One-command setup to stream Orbbec Astra Pro Plus camera feeds to a web interface.

## 🚀 One-Command Setup (Recommended)

Run this single command on your Raspberry Pi:

```bash
curl -fsSL https://raw.githubusercontent.com/Leenpwas/VARUNAVISION/main/quick-setup.sh | bash
```

Or if you have the repo cloned:

```bash
./quick-setup.sh
```

That's it! The streamer will be installed and started automatically.

Access at: `http://<RASPBERRY_PI_IP>:5000`

---

## Compatible With

- **Ubuntu 24.04** on Raspberry Pi (ARM64)
- **Raspberry Pi OS** (Legacy)
- Other Linux distributions with Python 3.7+

## Features

- **RGB Color Stream**: Normal color video feed
- **Depth Stream**: Colorized depth visualization
- **Object Detection**: Real-time color-based object detection
- **Web Interface**: Access streams from any device on your network
- **Auto-Start**: Automatically starts on boot
- **Fallback Mode**: Works with standard USB camera if Orbbec SDK unavailable

## Network Setup

```
[Router] <---> [Network Switch]
                |
                +---> [Raspberry Pi (BlueOS)] (provides hotspot)
                |
                +---> [Raspberry Pi + Orbbec Camera] (streams video)
                       |
                       +---> [Laptop/Client] (accesses website)
```

## Quick Start (One-Click Install)

### Step 1: Download to Raspberry Pi

```bash
# Copy the entire orbbec-streamer folder to your Raspberry Pi
# The folder should be at: ~/orbbec-streamer/
```

### Step 2: Run Installer

```bash
cd ~/orbbec-streamer
chmod +x install.sh
sudo ./install.sh
```

The installer will:
- Update system packages
- Install all dependencies (OpenCV, Flask, OpenNI2)
- Set up camera permissions
- Create systemd service
- Enable auto-start on boot

### Step 3: Start Streaming

```bash
sudo systemctl start orbbec-streamer
```

### Step 4: Access from Laptop

Find your Raspberry Pi's IP address:
```bash
hostname -I
```

Then open in browser:
```
http://<RASPBERRY_PI_IP>:5000
```

Example: `http://192.168.1.100:5000`

## Manual Setup (If Installer Fails)

### For Ubuntu 24.04

```bash
# 1. Install system dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-opencv v4l-utils

# 2. Install Python packages
pip3 install --user opencv-python numpy flask flask-cors pillow

# 3. Run streamer
cd ~/orbbec-streamer
python3 streamer.py
```

### For Raspberry Pi OS

```bash
# 1. Install system dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-opencv libopenni2-0

# 2. Install Python packages
pip3 install opencv-python numpy flask flask-cors pillow

# 3. Run streamer
cd ~/orbbec-streamer
python3 streamer.py
```

## Managing the Service

### Start/Stop/Restart

```bash
# Start
sudo systemctl start orbbec-streamer

# Stop
sudo systemctl stop orbbec-streamer

# Restart
sudo systemctl restart orbbec-streamer

# Check status
sudo systemctl status orbbec-streamer
```

### View Logs

```bash
# Real-time logs
sudo journalctl -u orbbec-streamer -f

# Last 100 lines
sudo journalctl -u orbbec-streamer -n 100
```

### Enable/Disable Auto-Start

```bash
# Enable auto-start on boot
sudo systemctl enable orbbec-streamer

# Disable auto-start on boot
sudo systemctl disable orbbec-streamer
```

## Troubleshooting

### Camera Not Detected

```bash
# Check if camera is connected
lsusb | grep Orbbec

# Test camera
v4l2-ctl --list-devices

# Check permissions
sudo chmod 666 /dev/video*
```

### Port 5000 Already in Use

Change port in `streamer.py` (last line):
```python
app.run(host='0.0.0.0', port=8000, debug=False, threaded=True)
```

### Low Performance

For better performance on Raspberry Pi:
- Reduce resolution in `streamer.py` (change 640 to 320)
- Close other applications
- Use Raspberry Pi 4 or 5

### OpenNI2 Issues

If automatic OpenNI2 installation fails:

1. Download manually:
```bash
cd ~/OpenNI2
wget https://github.com/code-iai/OpenNI2/releases
```

2. Install Orbbec SDK from:
   https://orbbec3d.com/develop/

3. Set environment variable:
```bash
export OPENNI2_DIR=~/OpenNI2/OpenNI-Linux-Arm64-2.3
```

## File Structure

```
orbbec-streamer/
├── install.sh          # One-click installer
├── streamer.py         # Main streaming application
├── templates/
│   └── index.html      # Web interface
├── README.md           # This file
└── logs/               # Log files (created at runtime)
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `/` | Web interface |
| `/video/color` | RGB color stream |
| `/video/depth` | Depth visualization stream |
| `/video/detection` | Object detection stream |
| `/status` | JSON status of all streams |

## Requirements

### Hardware
- Raspberry Pi 3, 4, or 5 (recommended)
- Orbbec Astra Pro Plus camera
- 1GB+ RAM

### Software
- **Ubuntu 24.04** (or Raspberry Pi OS)
- Python 3.7+
- Network connection

### Ubuntu 24.04 Specific Notes

- The installer automatically detects Ubuntu 24.04
- Uses `pip install --user` for Python packages
- Falls back to standard USB camera mode if Orbbec SDK unavailable
- Camera permissions handled via udev rules and video group

## License

MIT License - Free to use and modify

## Support

For issues:
1. Check logs: `sudo journalctl -u orbbec-streamer -n 100`
2. Verify camera: `lsusb | grep Orbbec`
3. Test camera: `python3 -c "import cv2; print(cv2.VideoCapture(0).isOpened())"`
