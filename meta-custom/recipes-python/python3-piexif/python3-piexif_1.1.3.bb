SUMMARY = "Piexif is a pure python library for EXIF"
DESCRIPTION = "To simplify exif manipulations with python. Writing, reading, and more..."
HOMEPAGE = "https://github.com/hMatoba/Piexif"
SECTION = "devel/python"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=5b1128e3f0fa15bb9c85786d53f1a17a"

PYPI_PACKAGE = "piexif"

inherit pypi setuptools3

SRC_URI[sha256sum] = "5f29d1c84fb0440a84d68c156846b62e59ebed1205cb38c88ed2c27e3a1f1ea1"

RDEPENDS:${PN} = "python3-core"
