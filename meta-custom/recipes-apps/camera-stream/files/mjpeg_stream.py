#!/usr/bin/env python3
"""
Simple MJPEG HTTP streaming server for Raspberry Pi camera
Uses V4L2 to capture MJPEG frames directly from the camera
"""

import fcntl
import mmap
import select
import socket
import v4l2
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
import threading
import time

# Camera configuration
CAMERA_DEVICE = "/dev/video0"
WIDTH = 1600
HEIGHT = 1200
FPS = 15
HTTP_PORT = 8080

class Camera:
    """Simple V4L2 camera capture using MJPEG format"""
    
    def __init__(self, device=CAMERA_DEVICE, width=WIDTH, height=HEIGHT):
        self.device = device
        self.width = width
        self.height = height
        self.fd = None
        self.buffers = []
        
    def open(self):
        """Open camera and configure for MJPEG capture"""
        # Open device
        self.fd = open(self.device, 'rb+', buffering=0)
        
        # Set format to MJPEG
        fmt = v4l2.v4l2_format()
        fmt.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
        fmt.fmt.pix.width = self.width
        fmt.fmt.pix.height = self.height
        fmt.fmt.pix.pixelformat = v4l2.V4L2_PIX_FMT_MJPEG
        fmt.fmt.pix.field = v4l2.V4L2_FIELD_NONE
        fcntl.ioctl(self.fd, v4l2.VIDIOC_S_FMT, fmt)
        
        # Set JPEG compression quality to maximum (100) for better image quality
        # Using the actual control ID from v4l2-ctl --list-ctrls
        try:
            ctrl = v4l2.v4l2_control()
            ctrl.id = 0x009d0903  # compression_quality control ID
            ctrl.value = 100  # Max quality (1-100, default is 30)
            fcntl.ioctl(self.fd, v4l2.VIDIOC_S_CTRL, ctrl)
            print(f"JPEG quality set to 100")
        except Exception as e:
            print(f"Could not set JPEG quality: {e}")
        
        # Increase video bitrate for better quality (default is 10Mbps, max is 25Mbps)
        try:
            ctrl = v4l2.v4l2_control()
            ctrl.id = 0x009909cf  # video_bitrate control ID
            ctrl.value = 17000000  # 17 Mbps (increased from 10 Mbps default)
            fcntl.ioctl(self.fd, v4l2.VIDIOC_S_CTRL, ctrl)
            print(f"Video bitrate set to 17 Mbps")
        except Exception as e:
            print(f"Could not set bitrate: {e}")
        
        # Request buffers
        req = v4l2.v4l2_requestbuffers()
        req.count = 4
        req.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
        req.memory = v4l2.V4L2_MEMORY_MMAP
        fcntl.ioctl(self.fd, v4l2.VIDIOC_REQBUFS, req)
        
        # Map buffers
        for i in range(req.count):
            buf = v4l2.v4l2_buffer()
            buf.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
            buf.memory = v4l2.V4L2_MEMORY_MMAP
            buf.index = i
            fcntl.ioctl(self.fd, v4l2.VIDIOC_QUERYBUF, buf)
            
            mm = mmap.mmap(self.fd.fileno(), buf.length, 
                          mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE,
                          offset=buf.m.offset)
            self.buffers.append(mm)
            
            # Queue buffer
            fcntl.ioctl(self.fd, v4l2.VIDIOC_QBUF, buf)
        
        # Start streaming
        buf_type = v4l2.v4l2_buf_type(v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE)
        fcntl.ioctl(self.fd, v4l2.VIDIOC_STREAMON, buf_type)
        
        print(f"Camera opened: MJPEG {self.width}x{self.height}")
        
    def read_frame(self):
        """Read a single MJPEG frame"""
        # Dequeue buffer
        buf = v4l2.v4l2_buffer()
        buf.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
        buf.memory = v4l2.V4L2_MEMORY_MMAP
        fcntl.ioctl(self.fd, v4l2.VIDIOC_DQBUF, buf)
        
        # Read frame data
        frame_data = self.buffers[buf.index][:buf.bytesused]
        
        # Re-queue buffer
        fcntl.ioctl(self.fd, v4l2.VIDIOC_QBUF, buf)
        
        return bytes(frame_data)
        
    def close(self):
        """Stop streaming and close camera"""
        if self.fd:
            buf_type = v4l2.v4l2_buf_type(v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE)
            fcntl.ioctl(self.fd, v4l2.VIDIOC_STREAMOFF, buf_type)
            self.fd.close()
            print("Camera closed")

# Global camera instance
camera = Camera()

class StreamingHandler(BaseHTTPRequestHandler):
    """HTTP request handler for MJPEG streaming"""
    
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'''
                <html>
                <head>
                    <title>Raspberry Pi Camera Stream</title>
                    <style>
                        body { text-align: center; background: #000; color: #fff; font-family: Arial; }
                        h1 { margin: 20px; }
                        #stream { transform: rotate(180deg); max-width: 100%; height: auto; }
                    </style>
                </head>
                <body>
                    <h1>Raspberry Pi Zero W Camera Stream</h1>
                    <img id="stream" src="/stream" width="1600" height="1200" />
                </body>
                </html>
            ''')
            
        elif self.path == '/stream':
            self.send_response(200)
            self.send_header('Content-type', 'multipart/x-mixed-replace; boundary=frame')
            self.end_headers()
            
            try:
                while True:
                    frame = camera.read_frame()
                    self.wfile.write(b'--frame\r\n')
                    self.send_header('Content-type', 'image/jpeg')
                    self.send_header('Content-length', str(len(frame)))
                    self.end_headers()
                    self.wfile.write(frame)
                    self.wfile.write(b'\r\n')
                    
            except Exception as e:
                print(f"Streaming error: {e}")
                
        else:
            self.send_error(404)
            
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """HTTP server with threading support"""
    daemon_threads = True

def main():
    """Main entry point"""
    global camera
    
    try:
        # Open camera
        camera.open()
        
        # Start HTTP server
        server = ThreadedHTTPServer(('0.0.0.0', HTTP_PORT), StreamingHandler)
        print(f"MJPEG streaming server started on port {HTTP_PORT}")
        print(f"Open http://192.168.5.73:{HTTP_PORT}/ in your browser")
        
        server.serve_forever()
        
    except KeyboardInterrupt:
        print("\nShutting down...")
    finally:
        camera.close()

if __name__ == '__main__':
    main()
