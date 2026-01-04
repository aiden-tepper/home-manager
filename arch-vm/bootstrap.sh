#!/usr/bin/env bash
set -e # Exit on error

echo "--- Starting Aiden's Nix-on-Arch Bootstrap ---"

# Before we begin, ensure tight permissions on btrfs snapshot dir for safety
sudo chmod 700 /.snapshots

# 1. Update Arch System & Install Hardware Handshake
# These are the things Nix can't/shouldn't manage on a non-NixOS system
echo "Installing System Foundations (Arch)..."
sudo pacman -Syu --needed --noconfirm \
    hyprland mesa xdg-desktop-portal-hyprland \
    qt6-wayland seatd kitty git

# 2. Enable System Services
echo "Enabling Seatd (for Wayland permissions)..."
sudo systemctl enable --now seatd
sudo usermod -aG seat,video,render $USER

# 3. Install Nix (Determinate Installer)
if ! command -v nix &> /dev/null; then
    echo "Nix not found. Installing..."
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
    # Source nix profile immediately
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
    echo "Nix is already installed."
fi

# 4. Apply Home Manager
echo "Applying Nix Flake..."
nix run github:nix-community/home-manager -- switch --flake .#spectre

echo "Bootstrap complete! Please REBOOT to finalize group permissions."
