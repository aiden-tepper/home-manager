#!/usr/bin/env bash
set -e

echo "--- Starting Bootstrap ---"

# Before we begin, ensure tight permissions on btrfs snapshot dir for safety
sudo chmod 700 /.snapshots

curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

sudo mkdir -p /persist/etc
sudo cp /etc/{passwd,shadow,group} /persist/etc/

cat <<FSTAB | sudo tee -a /etc/fstab
/persist/etc/passwd /etc/passwd none bind 0 0
/persist/etc/shadow /etc/shadow none bind 0 0
/persist/etc/group  /etc/group  none bind 0 0
FSTAB

# 1. Update System & Install GUI basics
sudo pacman -Syu --needed --noconfirm \
    hyprland mesa xdg-desktop-portal-hyprland \
    qt6-wayland seatd kitty git base-devel

sudo systemctl enable --now seatd

# 2. Permissions check
# Ensure user owns their persistent area (just in case)
sudo chown -R aiden:aiden /persist/home/aiden

# 3. Apply Home Manager
REPO_DIR="/home/aiden/projects/home-manager"
mkdir -p /home/aiden/projects

if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/aiden-tepper/home-manager "$REPO_DIR"
fi

cd "$REPO_DIR"

# Run the flake
make bootstrap

echo "Bootstrap complete! Reboot now."
