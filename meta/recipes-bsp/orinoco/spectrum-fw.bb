DESCRIPTION = "Firmware for Spectrum Wireless LAN cards"
DEPENDS += " unzip-native "
LICENSE = "closed"
PR = "r2"

SRC_URI = "http://ftp.osuosl.org/pub/nslu2/sources/MC&DriverOnlyInstallers.zip \
           file://get_symbol_fw \
           file://parse_symbol_fw"
S = "${WORKDIR}"

do_configure() {
	./get_symbol_fw
}

do_install() {
	install -d ${D}${base_libdir}/firmware/
	install -m 0755 ${WORKDIR}/symbol_sp24t_prim_fw ${D}${base_libdir}/firmware/symbol_sp24t_prim_fw
	install -m 0755 ${WORKDIR}/symbol_sp24t_sec_fw ${D}${base_libdir}/firmware/symbol_sp24t_sec_fw
}

PACKAGE_ARCH = "all"
FILES_${PN} += "${base_libdir}/firmware/symbol*"
