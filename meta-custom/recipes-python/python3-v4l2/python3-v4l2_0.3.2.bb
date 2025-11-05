SUMMARY = "Python bindings for the v4l2 userspace API"
DESCRIPTION = "This module provides python bindings for the v4l2 (Video4Linux2) userspace API"
HOMEPAGE = "https://github.com/antmicro/python3-v4l2"
SECTION = "devel/python"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "git://github.com/antmicro/python3-v4l2.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

inherit setuptools3

# Create videodev2 symlink for picamera2 compatibility
do_install:append() {
    # picamera2 expects 'videodev2' module but this package provides 'v4l2'
    # Create a compatibility symlink
    ln -sf v4l2.py ${D}${PYTHON_SITEPACKAGES_DIR}/videodev2.py
}

RDEPENDS:${PN} = " \
    python3-core \
"

DEPENDS = " \
    python3-setuptools-native \
"

