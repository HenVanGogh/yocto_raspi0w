SUMMARY = "Minimal stub for PyAV (av module) to allow picamera2 to import"
DESCRIPTION = "This is a minimal stub implementation of the av module. \
It provides just enough functionality to prevent import errors in picamera2. \
For full video encoding support, a complete PyAV implementation would be needed."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://av.py"

S = "${WORKDIR}"

inherit allarch

do_install() {
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}
    install -m 0644 ${WORKDIR}/av.py ${D}${PYTHON_SITEPACKAGES_DIR}/
}

FILES:${PN} = "${PYTHON_SITEPACKAGES_DIR}/av.py"

RDEPENDS:${PN} = "python3-core"
