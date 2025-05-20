SUMMARY = "INMP441 microphone test script"
DESCRIPTION = "Simple script to test the INMP441 I2S MEMS microphone"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://test-mic.sh"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/test-mic.sh ${D}${bindir}/test-mic
}

RDEPENDS:${PN} = "alsa-utils"
