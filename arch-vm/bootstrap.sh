#!/usr/bin/env bash
set -e # Exit on error

echo "--- Starting Aiden's Nix-on-Arch Bootstrap ---"

# Before we begin, ensure tight permissions on btrfs snapshot dir for safety
sudo chmod 700 /.snapshots

# 1. Update Arch System & Install Hardware Handshake
# These are the things Nix can't/shouldn't manage on a non-NixOS system
sudo pacman -Syu --needed --noconfirm \
    hyprland mesa xdg-desktop-portal-hyprland \
    qt6-wayland seatd kitty git base-devel

# 2. Enable System Services
sudo systemctl enable --now seatd

# Explicitly ensure the group exists (seatd usually creates it, but this is safe)
getent group seat || sudo groupadd -r seat

# Now add the user
sudo usermod -aG seat,video,render $USER

# 3. Install Nix (Determinate Installer)
if ! command -v nix &> /dev/null; then
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# 4. Create home for user-specific data in @persist subvol
sudo mkdir -p /persist/home/aiden
sudo chown aiden:aiden /persist/home/aiden
sudo chmod 700 /persist/home/aiden

# 5. Clone repo and apply Home Manager
REPO_DIR="/home/aiden/projects/home-manager"
mkdir -p /home/aiden/projects
git clone https://github.com/aiden-tepper/home-manager "$REPO_DIR"
cd "$REPO_DIR"
make bootstrap

echo "Bootstrap complete! Reboot now for user/group changes to take effect."
