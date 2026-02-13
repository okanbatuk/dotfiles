#!/bin/bash

# Default values
OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d "\"" -f2)
KERNEL=$(uname -r)
DE=$XDG_CURRENT_DESKTOP

case "$1" in
    "--light")
        # Mode: Light
        ARCH=$(uname -m | sed 's/x86_64/64-bit/' | sed 's/i[36]86/32-bit/')
        echo "OS: $OS_NAME"
        echo "Kernel: $KERNEL"
        echo "Architecture: $ARCH"
        echo "Desktop Environment: $DE"
        ;;
    "--full")
        # Mode: Full
        if command -v inxi &> /dev/null; then
            inxi -Fxzc0
        else
            echo "Error: 'inxi' is not installed. Install it with 'sudo pacman -S inxi'"
        fi
        ;;
    *)
        # Default Mode: Normal
        CPU=$(lscpu | grep "Model name" | cut -d ":" -f2 | xargs)
        RAM=$(free -h | awk '/^Mem:/ {print $2}')
        DISK=$(lsblk -dnio SIZE,MODEL | head -n 1)
        GPU=$(lspci | grep -i vga | cut -d ":" -f3 | xargs)
        
        echo "--- FULL SYSTEM INFO ---"
        echo "OS: $OS_NAME"
        echo "Kernel: $KERNEL"
        echo "CPU: $CPU"
        echo "RAM: $RAM"
        echo "Disk: $DISK"
        echo "GPU: $GPU"
        echo "DE: $DE"
        ;;
esac
