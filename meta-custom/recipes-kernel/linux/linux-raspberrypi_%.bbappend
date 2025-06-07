FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://wifi.cfg \
    file://i2s-audio.cfg \
    file://inmp441-overlay.dts \
"

KERNEL_MODULE_PROBECONF += "brcmfmac"
module_conf_brcmfmac = "options brcmfmac debug=1"

# Enable I2S in the device tree
RPI_KERNEL_DEVICETREE_OVERLAYS:append = " overlays/inmp441.dtbo"

# Compile and install the INMP441 device tree overlay
do_compile:append() {
    if [ -f ${WORKDIR}/inmp441-overlay.dts ]; then
        mkdir -p ${B}/arch/${ARCH}/boot/dts/overlays/
        ${B}/scripts/dtc/dtc -I dts -O dtb -o ${B}/arch/${ARCH}/boot/dts/overlays/inmp441.dtbo ${WORKDIR}/inmp441-overlay.dts
    fi
}

do_install:append() {
    if [ -f ${B}/arch/${ARCH}/boot/dts/overlays/inmp441.dtbo ]; then
        install -d ${D}/boot/overlays
        install -m 0644 ${B}/arch/${ARCH}/boot/dts/overlays/inmp441.dtbo ${D}/boot/overlays/
    fi
}

do_deploy:append() {
    if [ -f ${B}/arch/${ARCH}/boot/dts/overlays/inmp441.dtbo ]; then
        install -d ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/overlays
        install -m 0644 ${B}/arch/${ARCH}/boot/dts/overlays/inmp441.dtbo ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/overlays/
    fi
}

FILES:${PN} += "/boot/overlays/inmp441.dtbo"