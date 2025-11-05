#!/usr/bin/env python3
"""
Simple MJPEG HTTP streaming server for Raspberry Pi camera
Uses V4L2 to capture MJPEG frames directly - simplified version without mmap
"""

import fcntl
import select
import v4l2
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
import struct
import time

# Camera configuration
CAMERA_DEVICE = "/dev/video0"
WIDTH = 1920
HEIGHT = 1080
HTTP_PORT = 8080

class Camera:
    """Simple V4L2 camera capture using MJPEG format with read() instead of mmap"""
    
    def __init__(self, device=CAMERA_DEVICE, width=WIDTH, height=HEIGHT):
        self.device = device
        self.width = width
        self.height = height
        self.fd = None
        
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
        
        print(f"Camera opened: MJPEG {self.width}x{self.height}")
        
    def read_frame(self):
        """Read a single MJPEG frame using simple read()"""
        # Use select to wait for data
        ready = select.select([self.fd], [], [], 2.0)
        if ready[0]:
            # Read frame - for MJPEG, read in chunks and look for markers
            chunk_size = 4096
            frame_data = b''
            
            # Read until we find JPEG end marker (FF D9)
            while True:
                chunk = self.fd.read(chunk_size)
                if not chunk:
                    break
                frame_data += chunk
                
                # Check for JPEG end marker
                if b'\xff\xd9' in chunk:
                    # Found end of JPEG, truncate at the marker
                    idx = frame_data.find(b'\xff\xd9')
                    if idx != -1:
                        frame_data = frame_data[:idx+2]
                        break
                        
                # Safety limit - max 1MB per frame
                if len(frame_data) > 1024*1024:
                    break
                    
            return frame_data
        return None
        
    def close(self):
        """Close camera"""
        if self.fd:
            self.fd.close()
            print("Camera closed")

# Global camera instance
camera = None

class StreamingHandler(BaseHTTPRequestHandler):
    """HTTP request handler for MJPEG streaming"""
    
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'''
                <html>
                <head><title>Raspberry Pi Camera Stream</title></head>
                <body style="background-color: #222; color: #fff; font-family: Arial;">
                <h1>Raspberry Pi Zero W Camera Stream</h1>
                <img src="/stream" style="max-width: 100%; height: auto;" />
                <p>Resolution: ''' + f"{WIDTH}x{HEIGHT}".encode() + b'''</p>
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
                    if frame:
                        self.wfile.write(b'--frame\r\n')
                        self.wfile.write(b'Content-Type: image/jpeg\r\n')
                        self.wfile.write(f'Content-Length: {len(frame)}\r\n\r\n'.encode())
                        self.wfile.write(frame)
                        self.wfile.write(b'\r\n')
                    else:
                        time.sleep(0.01)
                    
            except BrokenPipeError:
                print("Client disconnected")
            except Exception as e:
                print(f"Streaming error: {e}")
                
        else:
            self.send_error(404)
            
    def log_message(self, format, *args):
        """Suppress default logging"""
        return

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """HTTP server with threading support"""
    daemon_threads = True
    allow_reuse_address = True

def main():
    """Main entry point"""
    global camera
    
    try:
        # Open camera
        camera = Camera()
        camera.open()
        
        # Start HTTP server
        server = ThreadedHTTPServer(('0.0.0.0', HTTP_PORT), StreamingHandler)
        print(f"MJPEG streaming server started on port {HTTP_PORT}")
        print(f"Open http://192.168.5.73:{HTTP_PORT}/ in your browser")
        
        server.serve_forever()
        
    except KeyboardInterrupt:
        print("\nShutting down...")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if camera:
            camera.close()

if __name__ == '__main__':
    main()
