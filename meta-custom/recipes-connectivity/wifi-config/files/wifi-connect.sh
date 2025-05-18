#!/bin/sh

# WiFi connection helper script
# This script attempts to establish WiFi connectivity by restarting services if needed

# Wait for WiFi firmware to initialize
sleep 10

# Check if WiFi interface is up
if ! ip link show wlan0 | grep -q "UP"; then
    echo "Bringing up wlan0 interface..."
    ip link set wlan0 up
    sleep 2
fi

# Check if wpa_supplicant is running
if ! systemctl is-active --quiet wpa_supplicant@wlan0.service; then
    echo "Starting wpa_supplicant service..."
    systemctl restart wpa_supplicant@wlan0.service
    sleep 5
fi

# Check for IP address
if ! ip addr show wlan0 | grep -q "inet "; then
    echo "No IP address. Restarting DHCP client..."
    systemctl restart dhcpcd@wlan0.service
    sleep 5
fi

# Final check
if ip addr show wlan0 | grep -q "inet "; then
    echo "WiFi successfully connected"
    exit 0
else
    echo "WiFi connection failed"
    # Try one more aggressive restart
    ip link set wlan0 down
    sleep 2
    ip link set wlan0 up
    sleep 2
    systemctl restart wpa_supplicant@wlan0.service
    sleep 5
    systemctl restart dhcpcd@wlan0.service
    exit 1
fi