FROM archlinux:latest

# Update system and install ONLY sudo for the orchestration
# All other tools (git, base-devel, etc.) will be handled by 01-system.sh
RUN pacman -Syyu --noconfirm && \
    pacman -S --noconfirm sudo

# Create a non-root user 'myrn' and grant passwordless sudo access
RUN useradd -m -s /bin/bash myrn && \
    echo "myrn ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set the working directory
WORKDIR /home/myrn/dotfiles

# Switch to the non-root user
USER myrn

# Keep the container alive for persistent testing
CMD ["tail", "-f", "/dev/null"]
