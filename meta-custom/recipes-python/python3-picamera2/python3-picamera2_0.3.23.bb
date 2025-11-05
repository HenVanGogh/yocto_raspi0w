SUMMARY = "The libcamera-based Python picamera2 library"
DESCRIPTION = "Picamera2 is the libcamera-based replacement for Picamera which \
was a Python interface to the Raspberry Pi's legacy camera stack. Picamera2 also \
presents an easy to use Python API."
HOMEPAGE = "https://github.com/raspberrypi/picamera2"
SECTION = "devel/python"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=6541a38108b5accb25bd55a14e76086d"

SRC_URI = "git://github.com/raspberrypi/picamera2.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

# Allow fetching latest version from git
PV = "0.3.23+git${SRCPV}"

inherit setuptools3

# Runtime dependencies
RDEPENDS:${PN} = " \
    python3-core \
    python3-numpy \
    python3-pillow \
    python3-prctl \
    python3-v4l2 \
    python3-piexif \
    python3-av-stub \
    libcamera \
    libcamera-pycamera \
"

# Build dependencies  
DEPENDS = " \
    python3-setuptools-native \
"

# picamera2 is architecture-specific due to libcamera bindings
PACKAGE_ARCH = "${MACHINE_ARCH}"
