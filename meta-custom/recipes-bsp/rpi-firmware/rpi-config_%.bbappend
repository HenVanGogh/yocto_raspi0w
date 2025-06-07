FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable I2S in the config.txt
ENABLE_I2S = "1"

# Add our custom config fragments
SRC_URI += "file://i2s.cfg"

# Add the INMP441 overlay in config.txt
RPI_EXTRA_CONFIG += "\n# INMP441 MEMS Microphone Configuration\ndtoverlay=inmp441\n"
