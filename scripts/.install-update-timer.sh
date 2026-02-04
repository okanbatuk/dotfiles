#!/bin/bash

SERVICE_DIR="$HOME/.config/systemd/user"
SCRIPT_PATH="$HOME/dotfiles/scripts/.update.sh"
TIMER_NAME="update-script"

mkdir -p "$SERVICE_DIR"

# .service dosyası
cat > "$SERVICE_DIR/$TIMER_NAME.service" <<EOF
[Unit]
Description=Weekly System Update Script

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

# .timer dosyası
cat > "$SERVICE_DIR/$TIMER_NAME.timer" <<EOF
[Unit]
Description=Run system update script weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# systemd user servisini yenile
systemctl --user daemon-reexec
systemctl --user daemon-reload

# Timer'ı aktif et
systemctl --user enable --now "$TIMER_NAME.timer"

echo "✅ Systemd timer installed and activated."
systemctl --user list-timers | grep "$TIMER_NAME"
