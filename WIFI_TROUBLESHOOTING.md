# Raspberry Pi Zero W - WiFi Troubleshooting Guide
Date: May 15, 2025

## Issue
WiFi is not connecting on the Raspberry Pi Zero W after successful boot.
The `wlan0` interface is not appearing in the `ip a` output.

## Troubleshooting Steps

1. Check if the wireless kernel module is loaded:
```
modprobe brcmfmac
lsmod | grep brcmfmac
```

2. Verify the firmware files are present:
```
ls -la /lib/firmware/brcm/
```
Look for `brcmfmac43430-sdio.bin` and `brcmfmac43430-sdio.txt` files.

3. Check systemd service status:
```
systemctl status wpa_supplicant-custom@wlan0.service
systemctl status dhcpcd@wlan0.service
```

4. Review logs for WiFi-related errors:
```
journalctl | grep -i wifi
journalctl | grep -i wlan
journalctl | grep -i brcm
```

5. Manually start the interface and services:
```
ip link set wlan0 up
systemctl restart wpa_supplicant-custom@wlan0.service
systemctl restart dhcpcd@wlan0.service
```

## Fixes to Apply

1. Make sure the kernel modules are loaded at boot by adding them to the `/etc/modules-load.d/wifi.conf` file.

2. Ensure the wpa_supplicant configuration file naming matches what's expected by the service.

3. Check that the systemd services are properly enabled and configured.

4. Verify that the firmware-loading happens correctly at boot time.

5. Enable debug logs for better troubleshooting:
```
wpa_supplicant -dd -Dnl80211 -iwlan0 -c/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
```