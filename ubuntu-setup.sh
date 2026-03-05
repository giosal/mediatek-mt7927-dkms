#!/bin/bash
set -e

# Target paths
PKG_NAME="mediatek-mt7927-ubuntu"
PKG_VER="7.4"
DKMS_DIR="/usr/src/${PKG_NAME}-${PKG_VER}"
KVER_BASE=$(uname -r | cut -d'-' -f1)
KVER_MINOR=$(echo $KVER_BASE | cut -d'.' -f1,2)
WL_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/net/wireless/mediatek/mt76"
BT_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/bluetooth"

echo "=========================================================="
echo "Starting MT7927 Setup (Pure Upstream v7.4 + Hardcoded ROG ID)"
echo "Target Kernel: $(uname -r)"
echo "=========================================================="

# 1. FIRMWARE PLACEMENT
echo "[1/5] Setting up Firmware..."
sudo mkdir -p /lib/firmware/mediatek/mt6639
sudo mkdir -p /lib/firmware/mediatek/mt7927
find ./firmware/bluetooth ./firmware/wifi -type f -name "*.bin" -exec sudo cp {} /lib/firmware/mediatek/mt6639/ \;
sudo cp /lib/firmware/mediatek/mt6639/WIFI_*.bin /lib/firmware/mediatek/mt7927/ 2>/dev/null || true
sudo cp /lib/firmware/mediatek/mt6639/BT_*.bin /lib/firmware/mediatek/ 2>/dev/null || true

# 2. BULLETPROOF DKMS CLEANUP
echo "[2/5] Cleaning DKMS Registry and Sources..."
for mod in "mediatek-bt-only" "mediatek-mt7927-wifi" "mediatek-mt7927" "mediatek-mt7927-ubuntu"; do
    sudo dkms remove -m $mod --all 2>/dev/null || true
    sudo rm -rf /var/lib/dkms/${mod}
    sudo rm -rf /usr/src/${mod}-*
done
sudo mkdir -p "${DKMS_DIR}/drivers/bluetooth" "${DKMS_DIR}/mt76/mt7921" "${DKMS_DIR}/mt76/mt7925"

# 3. DOWNLOAD KERNEL SOURCES
echo "[3/5] Downloading raw kernel sources for patching..."
dl_file() {
  local url_base=$1; local path=$2; local destdir=$3; local filename=$(basename "$path")
  for ref in "v${KVER_BASE}" "linux-${KVER_MINOR}.y" "v${KVER_MINOR}" "master"; do
    if sudo curl -s -f -o "${destdir}/${filename}" "${url_base}/${path}?h=${ref}"; then return 0; fi
  done
  echo "ERROR: Failed to download ${path}"; return 1
}
for f in "btusb.c" "btmtk.c" "btmtk.h" "btintel.h" "btbcm.h" "btrtl.h"; do dl_file "$BT_URL" "$f" "${DKMS_DIR}/drivers/bluetooth"; done

MT76_FILES=("mt76.h" "mt76_connac.h" "mt76_connac2_mac.h" "mt76_connac3_mac.h" "mt76_connac_mcu.h" "mt76_connac_mcu.c" "mt76_connac_mac.c" "mt76_connac3_mac.c" "mmio.c" "util.c" "util.h" "trace.c" "trace.h" "dma.c" "dma.h" "mac80211.c" "debugfs.c" "eeprom.c" "tx.c" "agg-rx.c" "mcu.c" "wed.c" "scan.c" "channel.c" "pci.c" "testmode.h" "mt792x.h" "mt792x_regs.h" "mt792x_core.c" "mt792x_mac.c" "mt792x_trace.c" "mt792x_trace.h" "mt792x_debugfs.c" "mt792x_dma.c" "mt792x_acpi_sar.c" "mt792x_acpi_sar.h" "sdio.h")
for f in "${MT76_FILES[@]}"; do dl_file "$WL_URL" "${f}" "${DKMS_DIR}/mt76"; done
MT7921_FILES=("mt7921.h" "mac.c" "mcu.c" "main.c" "init.c" "debugfs.c" "pci.c" "pci_mac.c" "pci_mcu.c" "sdio.c" "sdio_mac.c" "sdio_mcu.c" "regs.h" "mcu.h")
for f in "${MT7921_FILES[@]}"; do dl_file "$WL_URL" "mt7921/${f}" "${DKMS_DIR}/mt76/mt7921"; done
MT7925_FILES=("mt7925.h" "mac.c" "mac.h" "mcu.c" "mcu.h" "main.c" "init.c" "debugfs.c" "pci.c" "pci_mac.c" "pci_mcu.c" "regd.c" "regd.h" "regs.h" "mcu.h")
for f in "${MT7925_FILES[@]}"; do dl_file "$WL_URL" "mt7925/${f}" "${DKMS_DIR}/mt76/mt7925"; done

# 4. APPLY PURE UPSTREAM PATCHES + ROG HARDCODE
echo "[4/5] Applying jetm's patch files..."
sudo cp mt6639-*.patch mt7902-*.patch "${DKMS_DIR}/"
cd "${DKMS_DIR}"

# Patch Bluetooth
sudo patch -p1 < mt6639-bt-6.19.patch

# HARDCODE ROG ID: Force the exact 0489:e13a ID into the MT6639 device table
echo "  - Hardcoding ROG Bluetooth ID (0489:e13a) into btusb.c..."
sudo sed -i '/BTUSB_MEDIATEK | BTUSB_WIDEBAND_SPEECH/a \	{ USB_DEVICE(0x0489, 0xe13a), .driver_info = BTUSB_MEDIATEK | BTUSB_WIDEBAND_SPEECH | BTUSB_VALID_LE_STATES },' drivers/bluetooth/btusb.c

# Patch WiFi dynamically
cd "${DKMS_DIR}/mt76"
sudo patch -p1 < ../mt7902-wifi-6.19.patch || true
for p in $(ls ../mt6639-wifi-*.patch | sort); do
    echo "  - Applying $(basename $p)..."
    sudo patch -p1 < "$p"
done

# 5. BUILD FILES & INSTALL
echo "[5/5] Building and Installing..."
cd "${DKMS_DIR}"

sudo tee "dkms.conf" > /dev/null <<EOF
PACKAGE_NAME="${PKG_NAME}"
PACKAGE_VERSION="${PKG_VER}"
AUTOINSTALL="yes"
BUILT_MODULE_NAME[0]="btusb"; BUILT_MODULE_LOCATION[0]="drivers/bluetooth/"; DEST_MODULE_LOCATION[0]="/updates/dkms/"
BUILT_MODULE_NAME[1]="btmtk"; BUILT_MODULE_LOCATION[1]="drivers/bluetooth/"; DEST_MODULE_LOCATION[1]="/updates/dkms/"
BUILT_MODULE_NAME[2]="mt76"; BUILT_MODULE_LOCATION[2]="mt76/"; DEST_MODULE_LOCATION[2]="/updates/dkms/"
BUILT_MODULE_NAME[3]="mt76-connac-lib"; BUILT_MODULE_LOCATION[3]="mt76/"; DEST_MODULE_LOCATION[3]="/updates/dkms/"
BUILT_MODULE_NAME[4]="mt792x-lib"; BUILT_MODULE_LOCATION[4]="mt76/"; DEST_MODULE_LOCATION[4]="/updates/dkms/"
BUILT_MODULE_NAME[5]="mt7921-common"; BUILT_MODULE_LOCATION[5]="mt76/mt7921/"; DEST_MODULE_LOCATION[5]="/updates/dkms/"
BUILT_MODULE_NAME[6]="mt7921e"; BUILT_MODULE_LOCATION[6]="mt76/mt7921/"; DEST_MODULE_LOCATION[6]="/updates/dkms/"
BUILT_MODULE_NAME[7]="mt7925-common"; BUILT_MODULE_LOCATION[7]="mt76/mt7925/"; DEST_MODULE_LOCATION[7]="/updates/dkms/"
BUILT_MODULE_NAME[8]="mt7925e"; BUILT_MODULE_LOCATION[8]="mt76/mt7925/"; DEST_MODULE_LOCATION[8]="/updates/dkms/"
EOF

sudo tee "Makefile" > /dev/null <<'EOF'
obj-m += drivers/bluetooth/
obj-m += mt76/
EOF

sudo tee "drivers/bluetooth/Makefile" > /dev/null <<'EOF'
obj-m += btusb.o btmtk.o
ccflags-y := -I$(src)
EOF

sudo tee "mt76/Makefile" > /dev/null <<'EOF'
obj-m += mt76.o mt76-connac-lib.o mt792x-lib.o mt7921/ mt7925/
mt76-y := mmio.o util.o trace.o dma.o mac80211.o debugfs.o eeprom.o tx.o agg-rx.o mcu.o wed.o scan.o channel.o pci.o
mt76-connac-lib-y := mt76_connac_mcu.o mt76_connac_mac.o mt76_connac3_mac.o
mt792x-lib-y := mt792x_core.o mt792x_mac.o mt792x_trace.o mt792x_debugfs.o mt792x_dma.o mt792x_acpi_sar.o
ccflags-y := -I$(src)
EOF

sudo tee "mt76/mt7921/Makefile" > /dev/null <<'EOF'
obj-m += mt7921-common.o mt7921e.o
mt7921-common-y := mac.o mcu.o main.o init.o debugfs.o
mt7921e-y := pci.o pci_mac.o pci_mcu.o
ccflags-y := -I$(src) -I$(src)/..
EOF

sudo tee "mt76/mt7925/Makefile" > /dev/null <<'EOF'
obj-m += mt7925-common.o mt7925e.o
mt7925-common-y := mac.o mcu.o regd.o main.o init.o debugfs.o
mt7925e-y := pci.o pci_mac.o pci_mcu.o
ccflags-y := -I$(src) -I$(src)/..
EOF

sudo dkms add -m ${PKG_NAME} -v ${PKG_VER}
sudo dkms build -m ${PKG_NAME} -v ${PKG_VER}
sudo dkms install -m ${PKG_NAME} -v ${PKG_VER} --force
sudo update-initramfs -u

echo "=========================================================="
echo "Installation Complete! A Deep Cold Boot is required."
echo "=========================================================="
