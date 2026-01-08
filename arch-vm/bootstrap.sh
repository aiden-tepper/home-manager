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

sudo systemctl enable --now seatd

# --- IDENTITY HOLE-PUNCHING ---
# We must unmount these so groupadd/useradd can modify the real files on disk
echo "Temporarily unmounting identity files for configuration..."
sudo umount /etc/group || true
sudo umount /etc/passwd || true
sudo umount /etc/shadow || true

# 2. Back up the "ephemeral" versions and link to the PERSISTENT ones
# This forces the Nix installer to write directly to your vault.
sudo mv /etc/group /etc/group.bak
sudo mv /etc/passwd /etc/passwd.bak
sudo mv /etc/shadow /etc/shadow.bak

sudo ln -s /persist/etc/group /etc/group
sudo ln -s /persist/etc/passwd /etc/passwd
sudo ln -s /persist/etc/shadow /etc/shadow

# 3. Install Nix (Determinate Installer)
if ! command -v nix &> /dev/null; then
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# 4. Cleanup links and restore bind-mounts
sudo rm /etc/group /etc/passwd /etc/shadow
sudo mv /etc/group.bak /etc/group
sudo mv /etc/passwd.bak /etc/passwd
sudo mv /etc/shadow.bak /etc/shadow

sudo mount --bind /persist/etc/group /etc/group
sudo mount --bind /persist/etc/passwd /etc/passwd
sudo mount --bind /persist/etc/shadow /etc/shadow

sudo systemctl restart nix-daemon

# 5. Create home for user-specific data in @persist subvol
sudo mkdir -p /persist/home/aiden
sudo chown aiden:aiden /persist/home/aiden
sudo chmod 700 /persist/home/aiden

# 6. Clone repo and apply Home Manager
REPO_DIR="/home/aiden/projects/home-manager"
mkdir -p /home/aiden/projects
git clone https://github.com/aiden-tepper/home-manager "$REPO_DIR"
cd "$REPO_DIR"
make bootstrap

echo "Bootstrap complete! Reboot now for user/group changes to take effect."
