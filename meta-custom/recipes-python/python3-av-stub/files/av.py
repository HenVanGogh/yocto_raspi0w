# Minimal stub for PyAV to allow picamera2 to import
# This provides just enough to prevent import errors
# For full video encoding support, install the real PyAV package

class VideoStream:
    pass

class AudioStream:
    pass

class Container:
    def __init__(self, *args, **kwargs):
        pass
    
    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        pass

def open(*args, **kwargs):
    return Container()
