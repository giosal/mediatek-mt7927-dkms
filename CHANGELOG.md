# Changelog

All notable changes to the MediaTek MT7927 DKMS package are documented here.

Format: `v<pkgver>-<pkgrel>` where pkgver bumps for driver/patch changes
and pkgrel bumps for PKGBUILD packaging changes.

## [Unreleased]

### Documentation

- docs: Update README with known issues, fixes, and upstream status
- docs: Update upstream submission status in README

### Driver

- dkms: Add USB ID 0489:e110 to MT7927 Bluetooth device table

### Other

- scripts: Add automated release script for DKMS package
- .gitignore: Add linux-stable to ignored paths

### Packaging

- pkg: Distro-agnostic build system and bump to v2.4-1
## [2.3-1] - 2026-03-06

### Driver

- mt7927-wifi: Remove GitHub reporter/tester attribution from ASPM patch
- dkms/mt7927: Rebase patch series onto updated kernel tree
- mediatek-mt7927-dkms: Bump version to 2.3

### Other

- gitignore: Exclude .github/ (GitHub-only, AUR rejects subdirectories)
- CHANGELOG: Reorganize entries into reverse-chronological order
## [2.2-1] - 2026-03-06

### Documentation

- doc: Add udev rule for Bluetooth rfkill auto-unblock
- README: Remove MT6639 Bluetooth udev auto-unblock instructions
- README: Document project roadmap and known limitations
- README: Update status to reflect fixed WPA, AP mode, and MLO issues
- README: Add Bazzite packaging reference and fix patch sign-off
- docs: ASUS ProArt X870E BT USB ID
- docs: Add Gigabyte X870E Aorus Master X3D to supported hardware
- README: Update upstream tracking and recently fixed sections
- README: Update supported hardware table and detection commands
- docs: Add CHANGELOG for MediaTek MT7927 DKMS package

### Driver

- mediatek-mt7927-dkms: Add WiFi modules and auto-download support
- dkms: Reformat patchmodule script indentation
- wifi: Add MT6639/MT7927 WiFi support via mt7925e driver patches
- wifi/mt6639: Refine DMA initialization and power state handling
- drivers/net/wireless/mediatek/mt76: Add MT6639 combo chip support
- mediatek-mt7927-dkms: Bump pkgrel to 2
- mediatek-mt7927-dkms: Update device support list and patch checksums
- mediatek-mt7927-dkms: Bump package release and update checksums
- mediatek-mt7927-dkms: Bump package release to 5
- mt6639-bt: Add USB ID 13d3:3588 for ASUS X870E-E
- drivers/bluetooth: Add MT7927 USB ID for TP-Link TBE550E
- mediatek/bt: Bump pkgrel for MT6639 firmware persistence optimization
- mediatek-mt7927-dkms: Add WiFi 7 320MHz bandwidth support
- mediatek-mt7927-dkms: Replace EAPOL patch with connection state fix
- mediatek-mt7927-dkms: Remove upstream-merged WiFi connection patch
- mediatek-mt7927-dkms: Fix EAPOL frame handling during authentication
- drivers: Add MediaTek MT7927 WiFi 7/BT 5.4 DKMS package README
- mediatek-mt7927-dkms: Remove EAPOL RX header translation patch
- drivers/net: Fix stale pointer comparisons in MLO link teardown
- mediatek-mt7927-dkms: Refactor patch stack for upstream submission
- mt7927: Clarify authorship attribution in band-idx fix patch
- dkms: Add Tested-by tags from Marcin FM across all patches
- mt7927-dkms: Add three new Tested-by tags to all WiFi patches
- mt7927: Add 320MHz BSS RLM patch for mt7925 MCU

### Internal

- style: Convert indentation from spaces to tabs

### Other

- Initial release: DKMS bluetooth module for MediaTek MT7927 (MT6639)
- btusb-mt7927-dkms: Improve driver ZIP detection and toolchain handling
- fix is_mt6639_hw probe bug, enable PM, add 320MHz wiphy caps
- cliff.toml: Add git-cliff changelog configuration

### Packaging

- pkg: Generalize MT7927/MT6639 support to multiple OEM devices
- pkgbuild: Bump pkgrel to 2 for SRCDEST support
- pkgbuild: Add EAPOL frame patch to fix WiFi 6E authentication
- pkg: Switch to kernel tarball for source and remove download logic
- PKGBUILD: Split WiFi patches into numbered series, add MLO and mac_reset
- PKGBUILD: Bump pkgrel to 17 with MLO and MAC reset patch updates
- PKGBUILD: Bump pkgrel to 18 with patch commit headers
- pkg: Rename mt6639 to mt7927 in patches, PKGBUILD, and scripts
- pkg: Bump release to 2.1-20 with MT6639 BT patch fixes
- pkg: Drop EAPOL patch and renumber WiFi patch series
- PKGBUILD: Bump version to 2.2 and reset pkgrel to 1
- pkg: Bump version to 2.2-1 with new patches and test improvements

### Testing

- test-driver: Improve data path check robustness
- test-driver: Add failure tracking and improve error detection
- test-driver.sh: Expand diagnostic coverage for MT7927 hardware
- test-driver: Add EHT/WiFi 7 capability and channel width checks

