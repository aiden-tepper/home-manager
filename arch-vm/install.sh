#!/usr/bin/env bash
set -e

echo "--- Starting Unified Arch-Nix Installation ---"

# --- 1. Disk Prep ---
# 512MB EFI, Rest is Root
sgdisk --zap-all /dev/vda
sgdisk --new=1:0:+512M --typecode=1:ef00 /dev/vda
sgdisk --new=2:0:0     --typecode=2:8300 /dev/vda

mkfs.fat -F 32 -n BOOT /dev/vda1
mkfs.btrfs -L ARCH /dev/vda2

# --- 2. Subvolumes ---
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@           # Ephemeral Root
btrfs subvolume create /mnt/@nix        # Nix Store (Needs to be persisted)
btrfs subvolume create /mnt/@persist    # Configs
btrfs subvolume create /mnt/@log        # Logs
btrfs subvolume create /mnt/@pkg        # Pacman Cache
umount /mnt

# --- 3. Mounts ---
OPTS="compress=zstd,noatime"
mount -o $OPTS,subvol=@ /dev/vda2 /mnt

mkdir -p /mnt/{boot,nix,persist,var/log,var/cache/pacman/pkg}
mount /dev/vda1 /mnt/boot
mount -o $OPTS,subvol=@nix     /dev/vda2 /mnt/nix
mount -o $OPTS,subvol=@persist /dev/vda2 /mnt/persist
mount -o $OPTS,subvol=@log     /dev/vda2 /mnt/var/log
mount -o $OPTS,subvol=@pkg     /dev/vda2 /mnt/var/cache/pacman/pkg

# --- 4. Install Base + Nix ---
pacstrap -K /mnt base base-devel linux linux-firmware btrfs-progs git vim networkmanager sudo nix

genfstab -U /mnt >> /mnt/etc/fstab

# --- 5. Chroot Configuration ---
arch-chroot /mnt <<'EOF'
set -e

# System Identity
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch-nix-vm" > /etc/hostname

# User Setup
useradd -m -G wheel,nix-users aiden
echo "aiden:password" | chpasswd

# Nix Configuration (Enable Flakes)
mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
systemctl enable nix-daemon.service

# Services
systemctl enable NetworkManager

# --- Persist /etc Identity ---
# Now that Nix users exist, we can safely copy identity files to persist
mkdir -p /persist/etc
cp /etc/{passwd,shadow,group,machine-id} /persist/etc/

# Persist NetworkManager state
mkdir -p /persist/var/lib/networkmanager
mkdir -p /persist/etc/ssh

# Setup User Persistence
mkdir -p /persist/home/aiden/{.ssh,projects}
chown -R aiden:aiden /persist/home/aiden

# Append Bind Mounts to Fstab
cat <<FSTAB >> /etc/fstab

# --- PERSISTENCE ---
/persist/etc/passwd                /etc/passwd                none bind 0 0
/persist/etc/shadow                /etc/shadow                none bind 0 0
/persist/etc/group                 /etc/group                 none bind 0 0
/persist/etc/machine-id            /etc/machine-id            none bind 0 0
/persist/var/lib/networkmanager    /var/lib/networkmanager    none bind 0 0
/persist/etc/ssh                   /etc/ssh                   none bind 0 0
/persist/home/aiden/.ssh           /home/aiden/.ssh           none bind 0 0
/persist/home/aiden/projects       /home/aiden/projects       none bind 0 0
FSTAB

# --- 6. The "Erase My Darlings" Hook ---
# Build Hook
cat <<INST > /usr/lib/initcpio/install/erase-root
build() { add_runscript; }
help() { echo "Wipes @ and restores @blank"; }
INST

# Runtime Hook
cat <<HOOK > /usr/lib/initcpio/hooks/erase-root
run_hook() {
    mkdir -p /mnt-root
    mount -o subvolid=5 /dev/disk/by-label/ARCH /mnt-root
    btrfs subvolume delete /mnt-root/@
    btrfs subvolume snapshot /mnt-root/@blank /mnt-root/@
    umount /mnt-root
}
HOOK

# Register Hook & Rebuild
sed -i 's/HOOKS=(base udev/HOOKS=(base udev erase-root/' /etc/mkinitcpio.conf
mkinitcpio -P

# Bootloader
bootctl install
cat <<BOOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=LABEL=ARCH rootflags=subvol=@ rw
BOOT

EOF

# --- 7. Create Blank Snapshot ---
mkdir -p /mnt-temp
mount -o subvolid=5 /dev/vda2 /mnt-temp
btrfs subvolume snapshot -r /mnt-temp/@ /mnt-temp/@blank
umount /mnt-temp
rmdir /mnt-temp

echo "--- Install Complete. Reboot into your clean slate! ---"
