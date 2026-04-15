#!/bin/bash
# scripts/.alarm-notify.sh - Independent notification script

# Extract message or use default
MESSAGE="${1:-Scheduled task completed}"

# Explicitly export D-Bus address to ensure session contact
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

# Play a system sound in the background to avoid blocking the notification
# Manjaro GNOME default path for stereo sounds
if command -v paplay >/dev/null; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga &
fi

# Trigger GNOME desktop notification
# --urgency=critical: Forces immediate display and persistence
/usr/bin/notify-send "Times Up!" "$MESSAGE" \
    --urgency=critical \
    --icon=alarm-symbolic \
    --app-name="System Alarm"

# Brief pause to ensure D-Bus delivery before systemd cleans up the process
sleep 1
