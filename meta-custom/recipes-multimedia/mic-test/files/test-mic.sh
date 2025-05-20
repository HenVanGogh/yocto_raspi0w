#!/bin/sh
# Test script for INMP441 MEMS microphone

echo "Testing INMP441 microphone..."

# List ALSA devices
echo "=== Available ALSA devices ==="
aplay -l
echo ""
arecord -l
echo ""

# Test recording
echo "=== Testing microphone (recording for 5 seconds) ==="
arecord -d 5 -f S16_LE -c1 -r44100 -t wav test_recording.wav
echo "Recording saved as test_recording.wav"
echo ""

# Show controls
echo "=== ALSA controls ==="
amixer
echo ""

echo "Microphone test complete. To play back the recording, run: aplay test_recording.wav"
