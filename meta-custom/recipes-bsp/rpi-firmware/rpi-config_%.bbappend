FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable I2S in the config.txt
ENABLE_I2S = "1"

do_deploy:append() {
    # Additional I2S configuration for the INMP441 microphone
    echo "# INMP441 MEMS Microphone Configuration" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=inmp441" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtparam=i2s=on" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
}
