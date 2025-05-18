SUMMARY = "WiFi Configuration for Raspberry Pi Zero W"
DESCRIPTION = "Recipe to configure WiFi connectivity for Raspberry Pi Zero W"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://wpa_supplicant-wlan0.conf \
           file://wifi.conf"

S = "${WORKDIR}"

inherit systemd

do_install() {
    # Install WPA Supplicant configuration
    install -d ${D}${sysconfdir}/wpa_supplicant
    install -m 0600 ${WORKDIR}/wpa_supplicant-wlan0.conf ${D}${sysconfdir}/wpa_supplicant/wpa_supplicant-wlan0.conf

    # Create modules-load.d directory for autoloading WiFi modules
    install -d ${D}${sysconfdir}/modules-load.d/
    install -m 0644 ${WORKDIR}/wifi.conf ${D}${sysconfdir}/modules-load.d/
    
    # Create a startup script that brings up WiFi, but only if not already connected
    install -d ${D}${sysconfdir}/profile.d
    cat > ${D}${sysconfdir}/profile.d/wifi-setup.sh << EOF
#!/bin/sh
# Only initialize WiFi if not already connected
if ! ip addr show wlan0 | grep -q "inet "; then
    # Redirect all output to /dev/null to suppress messages
    ip link set wlan0 up >/dev/null 2>&1
    if ! pidof wpa_supplicant >/dev/null; then
        wpa_supplicant -B -q -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf >/dev/null 2>&1
        sleep 2 >/dev/null 2>&1
        udhcpc -q -i wlan0 >/dev/null 2>&1
    fi
fi
EOF
    chmod 0755 ${D}${sysconfdir}/profile.d/wifi-setup.sh

    # Create a systemd service to bring up WiFi - with reduced verbosity
    install -d ${D}${systemd_system_unitdir}
    cat > ${D}${systemd_system_unitdir}/wifi-setup.service << EOF
[Unit]
Description=WiFi Setup Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
# Redirect standard output to /dev/null to suppress messages
ExecStart=/bin/sh -c "ip link set wlan0 up >/dev/null 2>&1"
# Use -q for quiet operation of wpa_supplicant
ExecStart=/usr/sbin/wpa_supplicant -B -q -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
ExecStartPost=/bin/sleep 2
# Use -q for quiet operation of udhcpc
ExecStartPost=/sbin/udhcpc -q -i wlan0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Enable the service
    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants/
    ln -sf ${systemd_system_unitdir}/wifi-setup.service ${D}${sysconfdir}/systemd/system/multi-user.target.wants/wifi-setup.service
}

SYSTEMD_SERVICE:${PN} = "wifi-setup.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "${sysconfdir} ${systemd_system_unitdir}"
