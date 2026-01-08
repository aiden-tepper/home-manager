#!/usr/bin/env bash
set -e

echo "--- Installing Nix & Locking System ---"

# 1. Install Nix (Determinate)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 2. Persist Identity Files (Now containing Nix users)
sudo mkdir -p /persist/etc
sudo cp /etc/{passwd,shadow,group,machine-id} /persist/etc/

# 3. Permanently Bind-Mount Identity
cat <<FSTAB | sudo tee -a /etc/fstab
/persist/etc/passwd /etc/passwd none bind 0 0
/persist/etc/shadow /etc/shadow none bind 0 0
/persist/etc/group  /etc/group  none bind 0 0
/persist/etc/machine-id /etc/machine-id none bind 0 0
FSTAB

# 4. Pull Home Manager
REPO_DIR="$HOME/projects/home-manager"
mkdir -p ~/projects
git clone https://github.com/aiden-tepper/home-manager "$REPO_DIR"
cd "$REPO_DIR"

# Apply HM (this will create your symlinks in the home dir)
nix run github:nix-community/home-manager -- switch --flake .#spectre

echo "Bootstrap complete. Every reboot from now on will wipe the root subvolume!"
