#!/bin/sh

# DISK MOUNT
echo "Mounting local NTFS volume..."
sudo mkdir -p /run/media/myrn/LocalDisk
sudo ldmtool create all

MOUNT_POINT="/run/media/myrn/LocalDisk"
DEVICE="/dev/mapper/ldm_vol_DEV-WIN10-Dg0_Volume1"

if findmnt -rno TARGET "$DEVICE" | grep -q "$MOUNT_POINT"; then
  echo "✅ Volume is already mounted at $MOUNT_POINT"
else
  echo "📦 Volume not mounted. Attempting to mount..."
  sudo mkdir -p "$MOUNT_POINT"

  if sudo mount "$DEVICE"; then
    echo "✅ Successfully mounted $DEVICE to $MOUNT_POINT"
  else
    echo "❌ Failed to mount $DEVICE"
    echo "🔧 Checking for processes using the device:"
    sudo fuser -v "$DEVICE"
  fi
fi

