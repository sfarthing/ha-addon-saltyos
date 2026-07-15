#!/usr/bin/env bash
set -euo pipefail

PERSISTENT_DISK="/data/disk.img"
# SEED_DISK="/saltyos/disk.img.seed"
SEED_DISK="32M"

echo "Starting SaltyOS add-on..."

if [ ! -f "${PERSISTENT_DISK}" ]; then
    echo "No persistent disk image found."
    echo "Creating /data/disk.img from bundled seed disk..."
    # cp "${SEED_DISK}" "${PERSISTENT_DISK}"
    rm -f "${PERSISTENT_DISK}"
    qemu-img create -f raw "${PERSISTENT_DISK}" "${DISK_SIZE}"   
fi

echo "Using persistent disk: ${PERSISTENT_DISK}"

echo "Starting QEMU..."

qemu-system-x86_64 \
    -m 128 \
    -cdrom /saltyos/saltyos.iso \
    -drive file="${PERSISTENT_DISK}",format=raw,if=ide \
    -boot order=d \
    -display none \
    -vnc 0.0.0.0:0 \
    -no-reboot &

QEMU_PID=$!

echo "Starting noVNC on port 6080..."

websockify \
    --web=/usr/share/novnc/ \
    0.0.0.0:6080 \
    localhost:5900 &

WEBSOCKIFY_PID=$!

wait -n "${QEMU_PID}" "${WEBSOCKIFY_PID}"