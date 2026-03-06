# Maintainer: floss@jetm.me
#
# DKMS package for MediaTek MT7927 / MT6639 combo chip (Filogic 380):
#   - Bluetooth (MT6639 via USB): WORKING - patches btusb with MT6639 device ID
#     and installs firmware extracted from the MediaTek driver package.
#   - WiFi (MT7925e via PCIe): WORKING - patches mt7925e driver with MT7927
#     CBTOP remap, DMA ring layout, DBDC dual-band, and CNM channel context.
#     2.4/5/6 GHz tested, 320MHz EHT, suspend/resume.
#
# Sources mt76 + btusb from the kernel tarball (cdn.kernel.org) to avoid
# kernel.org CGI rate limits (503 errors after ~50 requests).
# Tracking:
#       https://github.com/openwrt/mt76/issues/927
#
# Known hardware using MT7927/MT6639:
#   - ASUS ROG Crosshair X870E Hero (BT USB 0489:e13a, WiFi PCI 14c3:7927)
#   - Lenovo Legion Pro 7 16ARX9      (BT USB 0489:e0fa, WiFi PCI 14c3:7927)
#   - Foxconn/Azurewave modules        (WiFi PCI 14c3:6639)
#   - AMD RZ738 (MediaTek MT7927)      (WiFi PCI 14c3:0738)
#   - ASUS ROG Zephyrus G14          (aftermarket MT7927 swap)
#   - TP-Link Archer TBE550E PCIe    (BT USB 0489:e116, E-key MT7927, extractable for laptop use)
#   - ASUS ProArt X870E              (WiFi PCI 14c3:7927)
#   - ASUS X870E-E                   (BT USB 13d3:3588, WiFi PCI 14c3:7927)
#   - Gigabyte Z790 AORUS MASTER X   (BT USB 0489:e10f, WiFi PCI 14c3:7927)
#
# MediaTek naming is confusing. Here's the map:
#   MT7927 = combo module on the motherboard (WiFi 7 + BT 5.4, Filogic 380)
#     ├─ BT side:   internally MT6639, connects via USB (0489:e13a)
#     └─ WiFi side: architecturally MT7925, connects via PCIe (14c3:7927)
#   MT7925 = standalone WiFi 7 chip — same silicon as MT7927's WiFi half
#   MT7902 = separate WiFi 6E chip (different product line, uses mt7921 driver)
#
# MT7902 WiFi modules (mt7921e) are included because:
#   - The mt76 driver framework is shared: building mt7925e already requires the
#     mt76 core, mt76-connac-lib, and mt792x-lib modules.
#   - mt7921e (which serves MT7902) shares the exact same dependency chain.
#   - Including it costs nothing extra and helps users with MT7902 hardware who
#     need the WiFi 6E patches from lore.kernel.org (Sean Wang's series).
#
# The ASUS driver ZIP is automatically downloaded from the ASUS CDN.
# Alternatively, manually download from your board's ASUS support page:
#   https://rog.asus.com/motherboards/rog-crosshair/rog-crosshair-x870e-hero/helpdesk_download/
#   → WiFi & Bluetooth → MediaTek MT7925/MT7927 WiFi driver
# Place the ZIP in this directory before running makepkg.

pkgname=mediatek-mt7927-dkms
pkgver=2.2
pkgrel=1
# Keywords: MT7927 MT7925 MT6639 MT7902 Filogic 380 WiFi 7 Bluetooth btusb mt7925e mt7921e
pkgdesc="DKMS Bluetooth (MT6639) and WiFi (MT7925e/MT7902) modules for MediaTek MT7927 Filogic 380"
arch=('x86_64')
url="https://github.com/jetm/mediatek-mt7927-dkms"
license=('GPL-2.0-only')
depends=('dkms')
makedepends=('python' 'curl')
provides=('mediatek-mt6639-bt-dkms' 'mediatek-mt7925-wifi-dkms')
conflicts=('btusb-mt7925-dkms' 'btusb-mt7927-dkms')
install=mediatek-mt7927-dkms.install

# NOTE: Newer firmware exists on station-drivers.com (v25.030.3.0057, 2026-01-18).
# Contains mtkwlan.dat at Wlan/Drivers/7925/mtkwlan.dat. Tested by marcin-fm - did
# not fix TX retransmissions. Requires manual browser download (JS-based).
#   https://station-drivers.com/index.php/en/component/remository/Drivers/MediaTek/MediaTek-MT7927-MT7925-Wireless-Lan/
_driver_filename='DRV_WiFi_MTK_MT7925_MT7927_TP_W11_64_V5603998_20250709R.zip'
_driver_sha256='b377fffa28208bb1671a0eb219c84c62fba4cd6f92161b74e4b0909476307cc8'

# Kernel version the mt76 WiFi patches target
_mt76_kver='6.19.6'

source=(
  "https://cdn.kernel.org/pub/linux/kernel/v${_mt76_kver%%.*}.x/linux-${_mt76_kver}.tar.xz"
  'extract_firmware.py'
  'dkms.conf'
  'dkms-patchmodule.sh'
)
sha256sums=('4d9f3ff73214f68c0194ef02db9ca4b7ba713253ac1045441d4e9f352bc22e14'
            'e94c77671abe0d589faa01c1a9451f626b1fc45fb04f765b43fd0e126d01a436'
            '9a650dd025aab38e2bb5d116e08cce79a6d215bd16d6d7d20e768e24d05d080b'
            'bd29eefcec618ec17d6ff3b6521d8292a6e092c3cbbdd1fca93b63e4c86a7fec')

# Auto-download via ASUS CDN token API.
# Based on code by Eadinator: https://github.com/openwrt/mt76/issues/927#issuecomment-3936022734
_download_driver_zip() {
  local _token_url="https://cdnta.asus.com/api/v1/TokenHQ?filePath=https:%2F%2Fdlcdnta.asus.com%2Fpub%2FASUS%2Fmb%2F08WIRELESS%2F${_driver_filename}%3Fmodel%3DROG%2520CROSSHAIR%2520X870E%2520HERO&systemCode=rog"

  echo "Fetching download token from ASUS CDN..."
  local _json
  _json="$(curl -sf "${_token_url}" -X POST -H 'Origin: https://rog.asus.com')"

  if [[ -z "${_json}" ]]; then
    echo >&2 "Failed to retrieve download token from ASUS CDN"
    return 1
  fi

  local _expires _signature _key_pair_id
  _expires=${_json#*\"expires\":\"}
  _expires=${_expires%%\"*}

  _signature=${_json#*\"signature\":\"}
  _signature=${_signature%%\"*}

  _key_pair_id=${_json#*\"keyPairId\":\"}
  _key_pair_id=${_key_pair_id%%\"*}

  local _download_url="https://dlcdnta.asus.com/pub/ASUS/mb/08WIRELESS/${_driver_filename}?model=ROG%20CROSSHAIR%20X870E%20HERO&Signature=${_signature}&Expires=${_expires}&Key-Pair-Id=${_key_pair_id}"

  echo "Downloading ${_driver_filename}..."
  if ! curl -L -f -o "${SRCDEST:-.}/${_driver_filename}" "${_download_url}"; then
    echo >&2 "Failed to download driver ZIP"
    return 1
  fi
}

prepare() {
  local _zips=("${SRCDEST:-.}"/DRV_WiFi_MTK_MT7925_MT7927*.zip)

  # Auto-download if no ZIP found
  if [[ ! -f "${_zips[0]}" ]]; then
    _download_driver_zip
    _zips=("${SRCDEST:-.}/${_driver_filename}")
  fi

  if [[ ! -f "${_zips[0]}" ]]; then
    echo >&2 "No ASUS MT7925/MT7927 WiFi driver ZIP available"
    echo "Download manually from your board's ASUS support page:"
    echo "  https://rog.asus.com/motherboards/rog-crosshair/rog-crosshair-x870e-hero/helpdesk_download/"
    echo "Select: WiFi & Bluetooth → MediaTek MT7925/MT7927 WiFi driver"
    echo "Place the ZIP in the PKGBUILD directory, then run makepkg again."
    return 1
  fi

  if (( ${#_zips[@]} > 1 )); then
    echo >&2 "Multiple ASUS driver ZIPs found — keep only one:"
    for z in "${_zips[@]}"; do echo "  $(basename "$z")"; done
    return 1
  fi

  # Verify integrity if using the known version
  if [[ "$(basename "${_zips[0]}")" == "${_driver_filename}" ]]; then
    echo "Verifying ${_driver_filename}..."
    echo "${_driver_sha256}  ${_zips[0]}" | sha256sum -c - || {
      echo >&2 "SHA256 mismatch for ${_driver_filename}"
      return 1
    }
  fi

  echo "Using driver ZIP: $(basename "${_zips[0]}")"
}

build() {
  local _zips=("${SRCDEST:-.}"/DRV_WiFi_MTK_MT7925_MT7927*.zip)

  # Extract BT + WiFi firmware from ASUS driver ZIP
  bsdtar -xf "${_zips[0]}" -C "${srcdir}" mtkwlan.dat
  python "${srcdir}/extract_firmware.py" "${srcdir}/mtkwlan.dat" "${srcdir}/firmware"

  # Extract mt76 and bluetooth source from kernel tarball
  echo "Extracting mt76 source from kernel v${_mt76_kver} tarball..."
  mkdir -p "${srcdir}/mt76"
  tar -xf "${srcdir}/linux-${_mt76_kver}.tar.xz" \
    --strip-components=6 \
    -C "${srcdir}/mt76" \
    "linux-${_mt76_kver}/drivers/net/wireless/mediatek/mt76"

  echo "Extracting bluetooth source..."
  mkdir -p "${srcdir}/bluetooth"
  tar -xf "${srcdir}/linux-${_mt76_kver}.tar.xz" \
    --strip-components=3 \
    -C "${srcdir}/bluetooth" \
    "linux-${_mt76_kver}/drivers/bluetooth"

  cd "${srcdir}/mt76"

  echo "Applying mt7902-wifi-6.19.patch..."
  patch -p1 < "${startdir}/mt7902-wifi-6.19.patch"

  echo "Applying MT7927 WiFi patches..."
  for _p in "${startdir}"/mt7927-wifi-*.patch; do
    echo "  $(basename "$_p")"
    patch -p1 < "$_p"
  done

  # Create Kbuild files for out-of-tree mt76 build
  cat > "${srcdir}/mt76/Kbuild" <<'EOF'
obj-m += mt76.o
obj-m += mt76-connac-lib.o
obj-m += mt792x-lib.o
obj-m += mt7921/
obj-m += mt7925/

mt76-y := \
	mmio.o util.o trace.o dma.o mac80211.o debugfs.o eeprom.o \
	tx.o agg-rx.o mcu.o wed.o scan.o channel.o pci.o

mt76-connac-lib-y := mt76_connac_mcu.o mt76_connac_mac.o mt76_connac3_mac.o

mt792x-lib-y := mt792x_core.o mt792x_mac.o mt792x_trace.o \
		mt792x_debugfs.o mt792x_dma.o mt792x_acpi_sar.o

CFLAGS_trace.o := -I$(src)
CFLAGS_mt792x_trace.o := -I$(src)
EOF

  cat > "${srcdir}/mt76/mt7921/Kbuild" <<'EOF'
obj-m += mt7921-common.o
obj-m += mt7921e.o

mt7921-common-y := mac.o mcu.o main.o init.o debugfs.o
mt7921e-y := pci.o pci_mac.o pci_mcu.o
EOF

  cat > "${srcdir}/mt76/mt7925/Kbuild" <<'EOF'
obj-m += mt7925-common.o
obj-m += mt7925e.o

mt7925-common-y := mac.o mcu.o regd.o main.o init.o debugfs.o
mt7925e-y := pci.o pci_mac.o pci_mcu.o
EOF

  echo "mt76 source prepared with MT7902 + MT7927 patches"
}

package() {
  local _dkmsdir="${pkgdir}/usr/src/mediatek-mt7927-${pkgver}"

  # Install DKMS config and scripts
  install -Dm644 "${srcdir}/dkms.conf" "${_dkmsdir}/dkms.conf"
  install -Dm755 "${srcdir}/dkms-patchmodule.sh" "${_dkmsdir}/dkms-patchmodule.sh"
  install -Dm644 "${startdir}/mt6639-bt-6.19.patch" "${_dkmsdir}/patches/bt/mt6639-bt-6.19.patch"
  install -dm755 "${_dkmsdir}/patches/wifi"
  install -m644 "${startdir}"/mt7927-wifi-*.patch "${_dkmsdir}/patches/wifi/"
  install -Dm755 "${srcdir}/extract_firmware.py" "${_dkmsdir}/extract_firmware.py"

  # Install pre-extracted bluetooth source for DKMS btusb builds
  install -dm755 "${_dkmsdir}/drivers/bluetooth"
  install -m644 "${srcdir}/bluetooth"/{btusb.c,btmtk.c,btmtk.h,btbcm.c,btbcm.h,btintel.h,btrtl.h} \
    "${_dkmsdir}/drivers/bluetooth/"

  # Install patched mt76 WiFi source tree
  install -dm755 "${_dkmsdir}/mt76/mt7921" "${_dkmsdir}/mt76/mt7925"
  install -m644 "${srcdir}/mt76"/*.{c,h} "${_dkmsdir}/mt76/"
  install -m644 "${srcdir}/mt76/Kbuild" "${_dkmsdir}/mt76/"
  install -m644 "${srcdir}/mt76/mt7921"/*.{c,h} "${_dkmsdir}/mt76/mt7921/"
  install -m644 "${srcdir}/mt76/mt7921/Kbuild" "${_dkmsdir}/mt76/mt7921/"
  install -m644 "${srcdir}/mt76/mt7925"/*.{c,h} "${_dkmsdir}/mt76/mt7925/"
  install -m644 "${srcdir}/mt76/mt7925/Kbuild" "${_dkmsdir}/mt76/mt7925/"

  # Install BT firmware
  install -Dm644 "${srcdir}/firmware/BT_RAM_CODE_MT6639_2_1_hdr.bin" \
    "${pkgdir}/usr/lib/firmware/mediatek/mt6639/BT_RAM_CODE_MT6639_2_1_hdr.bin"

  # Install WiFi firmware
  install -Dm644 "${srcdir}/firmware/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin" \
    "${pkgdir}/usr/lib/firmware/mediatek/mt7927/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin"
  install -Dm644 "${srcdir}/firmware/WIFI_RAM_CODE_MT6639_2_1.bin" \
    "${pkgdir}/usr/lib/firmware/mediatek/mt7927/WIFI_RAM_CODE_MT6639_2_1.bin"
}
