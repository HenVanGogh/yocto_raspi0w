SUMMARY = "MJPEG camera streaming server for Raspberry Pi"
DESCRIPTION = "Simple HTTP server that streams MJPEG video from the Raspberry Pi camera using V4L2"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://mjpeg_stream.py \
    file://camera-stream.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "camera-stream.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} = " \
    python3-core \
    python3-mmap \
    python3-fcntl \
    python3-ctypes \
    python3-threading \
    python3-v4l2 \
"

do_install() {
    # Install the Python script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mjpeg_stream.py ${D}${bindir}/
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/camera-stream.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${bindir}/mjpeg_stream.py \
    ${systemd_system_unitdir}/camera-stream.service \
"
