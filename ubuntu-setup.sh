#!/bin/bash
set -e

REPO_DIR="$(pwd)"

# Dynamically read DKMS package name and version from the repo's dkms.conf
PKG_NAME=$(grep -m1 '^PACKAGE_NAME=' dkms.conf | cut -d'"' -f2)
PKG_VER=$(grep -m1 '^PACKAGE_VERSION=' dkms.conf | cut -d'"' -f2)
DKMS_DIR="/usr/src/${PKG_NAME}-${PKG_VER}"

KVER_BASE=$(uname -r | cut -d'-' -f1)
KVER_MINOR=$(echo $KVER_BASE | cut -d'.' -f1,2)
TARBALL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KVER_MINOR}.tar.xz"

echo "=========================================================="
echo "Starting MT7927 Setup (Synced with latest jetm patches)"
echo "Target Kernel: $(uname -r)"
echo "DKMS Package: ${PKG_NAME} v${PKG_VER}"
echo "=========================================================="

# 0. THE SCORCHED EARTH CLEANUP
echo "[0/5] Purging all previous hacks, rules, and DKMS modules..."
sudo rm -f /etc/udev/rules.d/99-mediatek-bt.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo rm -f /etc/modprobe.d/mt7927.conf
sudo rm -f /etc/modprobe.d/btusb.conf

for mod in "mediatek-bt-only" "mediatek-mt7927-wifi" "mediatek-mt7927" "mediatek-mt7927-ubuntu" "${PKG_NAME}"; do
    sudo dkms remove -m $mod --all 2>/dev/null || true
    sudo rm -rf /var/lib/dkms/${mod}
    sudo rm -rf /usr/src/${mod}-*
done

sudo rm -f /lib/modules/$(uname -r)/updates/dkms/btusb.ko*
sudo rm -f /lib/modules/$(uname -r)/updates/dkms/mt76*.ko*
sudo rm -f /lib/modules/$(uname -r)/updates/dkms/mt79*.ko*
sudo depmod -a

# 1. FIRMWARE PLACEMENT
echo "[1/5] Setting up Firmware in mt6639/mt7927 directories..."
sudo mkdir -p /lib/firmware/mediatek/mt6639
sudo mkdir -p /lib/firmware/mediatek/mt7927

# Determine firmware directory dynamically
FW_DIR="firmware"
if [ -d "firmware/wifi" ]; then FW_DIR="firmware/wifi"; fi

sudo cp ${FW_DIR}/BT_RAM_CODE_MT6639_2_1_hdr.bin /lib/firmware/mediatek/mt6639/ || echo "Warning: BT firmware missing"
sudo cp ${FW_DIR}/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin /lib/firmware/mediatek/mt7927/ || echo "Warning: WiFi MCU missing"
sudo cp ${FW_DIR}/WIFI_RAM_CODE_MT6639_2_1.bin /lib/firmware/mediatek/mt7927/ || echo "Warning: WiFi RAM missing"

# 2. DOWNLOAD UPSTREAM SOURCES
echo "[2/5] Downloading kernel source tarball to avoid rate limits..."
sudo mkdir -p "${DKMS_DIR}"
sudo wget -q -O /tmp/linux.tar.xz "${TARBALL_URL}"

echo "      Extracting mt76 and bluetooth source directories..."
sudo tar -xf /tmp/linux.tar.xz --strip-components=1 -C "${DKMS_DIR}" "linux-${KVER_MINOR}/drivers/bluetooth"
sudo mkdir -p "${DKMS_DIR}/mt76"
sudo tar -xf /tmp/linux.tar.xz --strip-components=6 -C "${DKMS_DIR}/mt76" "linux-${KVER_MINOR}/drivers/net/wireless/mediatek/mt76"
sudo rm /tmp/linux.tar.xz

# 3. APPLY NATIVE PATCHES
echo "[3/5] Applying jetm's patches cleanly..."
# The patches are now prefixed with mt7927-wifi
sudo cp mt6639-bt-6.19.patch mt7902-wifi-6.19.patch mt7927-wifi-*.patch "${DKMS_DIR}/"

cd "${DKMS_DIR}"
echo "  - Patching Bluetooth for MT6639..."
sudo patch -p1 < mt6639-bt-6.19.patch

cd "${DKMS_DIR}/mt76"
echo "  - Patching WiFi for MT7902/MT7927..."
sudo patch -p1 < ../mt7902-wifi-6.19.patch || true
for p in $(ls ../mt7927-wifi-*.patch | sort); do
    echo "  - Applying $(basename $p)..."
    sudo patch -p1 < "$p"
done

# 4. BUILD FILES & DKMS CONFIG
echo "[4/5] Copying Makefiles and dkms.conf from repo..."
cd "${DKMS_DIR}"

# Replaced manual Makefiles with the native repository files
sudo cp "${REPO_DIR}/dkms.conf" "${DKMS_DIR}/dkms.conf"
sudo cp "${REPO_DIR}/bluetooth.Makefile" "${DKMS_DIR}/drivers/bluetooth/Makefile"
sudo cp "${REPO_DIR}/mt76.Kbuild" "${DKMS_DIR}/mt76/Makefile"
sudo cp "${REPO_DIR}/mt7921.Kbuild" "${DKMS_DIR}/mt76/mt7921/Makefile"
sudo cp "${REPO_DIR}/mt7925.Kbuild" "${DKMS_DIR}/mt76/mt7925/Makefile"

# Create a master Makefile to build both directories
sudo tee "Makefile" > /dev/null <<'EOF'
obj-m += drivers/bluetooth/
obj-m += mt76/
EOF

# Ensure the MediaTek config flag is present for Ubuntu out-of-tree DKMS compilation
echo "      Injecting MediaTek config flag into Bluetooth Makefile..."
sudo sed -i 's/$/\nccflags-y += -DCONFIG_BT_HCIBTUSB_MTK=y/' "${DKMS_DIR}/drivers/bluetooth/Makefile"

# 5. DKMS INSTALLATION
echo "[5/5] Compiling and Installing..."
sudo dkms add -m ${PKG_NAME} -v ${PKG_VER}
sudo dkms build -m ${PKG_NAME} -v ${PKG_VER}
sudo dkms install -m ${PKG_NAME} -v ${PKG_VER} --force
sudo update-initramfs -u

echo "=========================================================="
echo "CLEAN INSTALL COMPLETE!"
echo "You MUST perform a Deep Cold Boot (PSU off for 30 seconds)."
echo "=========================================================="
