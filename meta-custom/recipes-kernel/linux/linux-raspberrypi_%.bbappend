FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://wifi.cfg"

KERNEL_MODULE_AUTOLOAD += "brcmfmac"
KERNEL_MODULE_PROBECONF += "brcmfmac"
module_conf_brcmfmac = "options brcmfmac debug=1"