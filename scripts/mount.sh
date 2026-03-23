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

# Attempt to mount the NTFS volume
# The service runs as root, so sudo is not required within the script
if mount "$DEVICE" "$MOUNT_POINT"; then
    echo "✅ Successfully mounted $DEVICE to $MOUNT_POINT"
else
    echo "❌ Failed to mount $DEVICE"
    # Provide diagnostic information in case of failure
    # This will be captured in the systemd journal (journalctl -u mount-ldm.service)
    echo "🔧 Diagnostic: Checking for processes using the device..."
    fuser -v "$DEVICE" 2>/dev/null
    exit 1
fi
