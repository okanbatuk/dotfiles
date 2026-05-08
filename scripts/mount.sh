#!/bin/bash

# Define mount point and device path
# Using the specific LDM volume mapper device
MOUNT_POINT="/run/media/myrn/LocalDisk"
DEVICE="/dev/mapper/ldm_vol_DEV-WIN10-Dg0_Volume1"

# Ensure the mount point directory exists
# Using -p to avoid errors if the directory is already present
mkdir -p "$MOUNT_POINT"

# Initialize Logical Disk Manager (LDM) volumes
# Redirecting output to /dev/null to keep boot logs clean
/usr/bin/ldmtool create all > /dev/null 2>&1

# Check if the device is already mounted to prevent redundant mount attempts
# This optimization saves I/O cycles during boot
if mountpoint -q "$MOUNT_POINT"; then
    echo "✅ Volume is already mounted at $MOUNT_POINT"
    exit 0
fi

# Attempt to mount the NTFS volume with explicit driver fallback
# First attempt: ntfs-3g (usually more compatible with LDM/dirty volumes)
if mount -t ntfs-3g "$DEVICE" "$MOUNT_POINT"; then
    echo "✅ Successfully mounted $DEVICE to $MOUNT_POINT using ntfs-3g"
elif mount -t ntfs3 "$DEVICE" "$MOUNT_POINT"; then
    echo "✅ Successfully mounted $DEVICE to $MOUNT_POINT using ntfs3"
else
    echo "❌ Failed to mount $DEVICE"
    # Provide diagnostic information
    echo "🔧 Diagnostic: Checking dmesg for mount errors..."
    dmesg | tail -n 15
    exit 1
fi
