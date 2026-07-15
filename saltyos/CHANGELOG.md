# Changelog

## 1.2.0

- disable seed disk.img, modify code to create a new 32MB disk with formatted FAT16 Volume called SALTYOS, the new disk is created on initial installation within Home Assistant.

## 1.1.3.1

- Enabled Home Assistant Ingress support.
- Added noVNC WebSocket streaming support.
- Added SaltyOS sidebar/panel metadata.
- Kept direct noVNC access on port 6080.
- Kept raw VNC access on port 5900.

## 1.1.2

- Updated Web UI URL handling.

## 1.0.1

- Exposed noVNC web access on port 6080.
- Added raw VNC access on port 5900.

## 1.0.0

- Initial SaltyOS Home Assistant add-on.
- Boots SaltyOS using QEMU.
- Uses bundled ISO and seed disk image.
