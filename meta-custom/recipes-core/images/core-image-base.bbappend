# Minimal WiFi support for Raspberry Pi Zero W
# This replaces multiple overlapping recipes with a clean setup

# Basic WiFi packages needed - moved from RRECOMMENDS to IMAGE_INSTALL
IMAGE_INSTALL:append:raspberrypi0-wifi = " linux-firmware-rpidistro-bcm43430 wpa-supplicant iw wifi-config"

# Add bash shell
IMAGE_INSTALL:append = " bash bash-completion"

# Make bash the default shell instead of busybox ash
VIRTUAL-RUNTIME_login_manager = "busybox"
VIRTUAL-RUNTIME_base-utils = "busybox"
PREFERRED_PROVIDER_virtual/base-utils = "busybox"
PREFERRED_PROVIDER_virtual/sh = "bash"

# Make sure module autoloads properly
KERNEL_MODULE_AUTOLOAD:rpi += "brcmfmac"

# Clean up conflicting packages if they're installed



