#!/usr/bin/env python3
"""
Orbbec Astra Pro Plus Streamer
Streams three video types: RGB, Depth, and Object Detection
"""

import cv2
import numpy as np
import threading
import time
from flask import Flask, Response, render_template, jsonify
import os

app = Flask(__name__)

# Global frame storage
frames = {
    'color': None,
    'depth': None,
    'detection': None
}

frame_lock = threading.Lock()

class OrbbecCamera:
    def __init__(self):
        self.running = False
        self.cap_color = None
        self.cap_depth = None

        # Try different methods to access Orbbec camera
        self.init_camera()

    def init_camera(self):
        """Initialize camera connection"""
        print("Initializing Orbbec Astra Pro Plus...")

        # Method 1: Try OpenNI2
        try:
            from openni import openni2
            openni2.initialize()

            # Try to open device
            dev = openni2.Device.open_any()
            print("✓ OpenNI2 device opened successfully")

            # Configure color stream
            self.color_stream = dev.create_color_stream()
            self.color_stream.start()

            # Configure depth stream
            self.depth_stream = dev.create_depth_stream()
            self.depth_stream.start()

            self.use_openni = True
            return

        except Exception as e:
            print(f"OpenNI2 not available: {e}")

        # Method 2: Try standard USB camera (color only)
        print("Trying standard USB camera interface...")
        self.cap_color = cv2.VideoCapture(0)

        if self.cap_color.isOpened():
            # Set resolution
            self.cap_color.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
            self.cap_color.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
            self.cap_color.set(cv2.CAP_PROP_FPS, 30)
            print("✓ Color camera opened")
            self.use_openni = False
        else:
            raise Exception("Could not open any camera")

    def get_color_frame(self):
        """Get color frame"""
        if self.use_openni:
            try:
                frame = self.color_stream.read_frame()
                data = np.frombuffer(frame.get_buffer_as_uint8(), dtype=np.uint8)
                return data.reshape((frame.height, frame.width, 3))
            except:
                return None
        else:
            ret, frame = self.cap_color.read()
            return frame if ret else None

    def get_depth_frame(self):
        """Get depth frame"""
        if self.use_openni:
            try:
                frame = self.depth_stream.read_frame()
                data = np.frombuffer(frame.get_buffer_as_uint16(), dtype=np.uint16)
                depth = data.reshape((frame.height, frame.width))

                # Colorize depth map
                depth_colored = self.colorize_depth(depth)
                return depth_colored
            except:
                return None
        else:
            # Simulated depth using color image
            color = self.get_color_frame()
            if color is not None:
                gray = cv2.cvtColor(color, cv2.COLOR_BGR2GRAY)
                return self.colorize_depth(gray)
            return None

    def colorize_depth(self, depth):
        """Convert depth data to colored visualization"""
        # Normalize depth to 0-255
        depth_normalized = cv2.normalize(depth, None, 0, 255, cv2.NORM_MINMAX)

        # Apply color map
        depth_colored = cv2.applyColorMap(depth_normalized.astype(np.uint8), cv2.COLORMAP_JET)

        return depth_colored

    def release(self):
        """Release camera resources"""
        self.running = False
        if self.cap_color:
            self.cap_color.release()
        if self.use_openni:
            try:
                self.color_stream.stop()
                self.depth_stream.stop()
            except:
                pass


def detect_objects(frame):
    """Simple object detection using color segmentation"""
    if frame is None:
        return frame

    # Convert to HSV for better color detection
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

    # Detect various colored objects
    color_ranges = [
        # Red
        ([0, 100, 100], [10, 255, 255], "Red"),
        ([160, 100, 100], [180, 255, 255], "Red"),
        # Green
        ([40, 50, 50], [80, 255, 255], "Green"),
        # Blue
        ([100, 50, 50], [130, 255, 255], "Blue"),
        # Yellow
        ([20, 100, 100], [40, 255, 255], "Yellow"),
    ]

    result_frame = frame.copy()

    for lower, upper, label in color_ranges:
        lower = np.array(lower)
        upper = np.array(upper)

        # Create mask
        mask = cv2.inRange(hsv, lower, upper)

        # Find contours
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        for contour in contours:
            area = cv2.contourArea(contour)

            # Filter small objects
            if area > 500:
                # Get bounding box
                x, y, w, h = cv2.boundingRect(contour)

                # Draw rectangle
                cv2.rectangle(result_frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

                # Draw label
                cv2.putText(result_frame, f"{label}", (x, y - 10),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

    return result_frame


def camera_thread():
    """Background thread to capture and process frames"""
    global frames

    camera = OrbbecCamera()
    camera.running = True

    frame_count = 0
    last_time = time.time()

    while camera.running:
        try:
            # Get color frame
            color_frame = camera.get_color_frame()

            if color_frame is not None:
                # Resize for performance
                color_frame = cv2.resize(color_frame, (640, 480))

                # Get depth frame
                depth_frame = camera.get_depth_frame()
                if depth_frame is not None:
                    depth_frame = cv2.resize(depth_frame, (640, 480))

                # Get detection frame
                detection_frame = detect_objects(color_frame)

                # Update global frames
                with frame_lock:
                    frames['color'] = color_frame
                    frames['depth'] = depth_frame
                    frames['detection'] = detection_frame

                frame_count += 1
                if frame_count % 30 == 0:
                    fps = 30 / (time.time() - last_time)
                    print(f"Streaming at {fps:.1f} FPS")
                    last_time = time.time()

            time.sleep(0.033)  # ~30 FPS

        except Exception as e:
            print(f"Error in camera thread: {e}")
            time.sleep(1)

    camera.release()


def encode_frame(frame):
    """Encode frame to JPEG"""
    if frame is None:
        return None
    ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
    return buffer.tobytes() if ret else None


@app.route('/')
def index():
    """Main page"""
    return render_template('index.html')


@app.route('/video/<stream_type>')
def video_feed(stream_type):
    """Video streaming route"""
    def generate():
        while True:
            with frame_lock:
                frame = frames.get(stream_type)

            if frame is not None:
                encoded = encode_frame(frame)
                if encoded:
                    yield (b'--frame\r\n'
                           b'Content-Type: image/jpeg\r\n\r\n' + encoded + b'\r\n')

            time.sleep(0.033)

    return Response(generate(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')


@app.route('/status')
def status():
    """API status endpoint"""
    with frame_lock:
        status = {
            'streams': {
                'color': frames['color'] is not None,
                'depth': frames['depth'] is not None,
                'detection': frames['detection'] is not None
            }
        }
    return jsonify(status)


if __name__ == '__main__':
    # Start camera thread
    cam_thread = threading.Thread(target=camera_thread, daemon=True)
    cam_thread.start()

    # Get IP address
    import socket
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)

    print(f"\n{'='*50}")
    print(f"Orbbec Streamer Running!")
    print(f"{'='*50}")
    print(f"Access the web interface at:")
    print(f"  http://{ip_address}:5000")
    print(f"  http://localhost:5000")
    print(f"{'='*50}\n")

    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
