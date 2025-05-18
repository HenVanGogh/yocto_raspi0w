# WiFi support for Raspberry Pi Zero W
# Based on the same configuration used for core-image-base

# Basic WiFi packages needed
IMAGE_INSTALL:append:raspberrypi0-wifi = " linux-firmware-rpidistro-bcm43430 wpa-supplicant iw wifi-config"

# Add SSH support
IMAGE_INSTALL:append = " openssh openssh-sshd openssh-sftp-server"
PACKAGECONFIG:append:pn-openssh = " systemd"

# Add bash shell
IMAGE_INSTALL:append = " bash bash-completion"

# Make bash the default shell instead of busybox ash
PREFERRED_PROVIDER_virtual/sh = "bash"

# Make sure module autoloads properly
KERNEL_MODULE_AUTOLOAD:rpi += "brcmfmac"

# Clean up conflicting packages if they're installed
RCONFLICTS:${PN}:append:raspberrypi0-wifi = " \
    pi-zero-firmware-fix \
    pi-zero-w-firmware \
    rpi-direct-firmware \
    rpi-fixed-firmware \
    linux-firmware-bcm43430 \
"