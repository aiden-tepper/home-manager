#!/usr/bin/env bash
set -e

echo "--- Starting Unified Arch-Nix Installation ---"

# Setup Partitions
mkfs.fat -F 32 -n BOOT /dev/vda1
mkfs.btrfs -L ARCH /dev/vda2

# Define the mount options for SSD performance
# - compress=zstd: Saves space and SSD wear
# - noatime: Stops the OS from writing to the disk every time you just 'read' a file
OPTS="compress=zstd,noatime"

# Create Subvolumes
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@             # Ephemeral Root
btrfs subvolume create /mnt/@nix          # Persistent Nix Store
btrfs subvolume create /mnt/@persist      # Persistent System Configs
btrfs subvolume create /mnt/@log          # Persistent Logs
btrfs subvolume create /mnt/@pkg          # Persistent Pacman Cache
btrfs subvolume create /mnt/@db           # Persistent Pacman Database

umount /mnt

# Mount everything in place
mount -o $OPTS,subvol=@ /dev/vda2 /mnt
mkdir -p /mnt/{boot,nix,persist,var/log,var/cache/pacman/pkg,var/lib/pacman}

mount /dev/vda1 /mnt/boot
mount -o $OPTS,subvol=@nix /dev/vda2 /mnt/nix
mount -o $OPTS,subvol=@persist /dev/vda2 /mnt/persist
mount -o $OPTS,subvol=@log /dev/vda2 /mnt/var/log
mount -o $OPTS,subvol=@pkg /dev/vda2 /mnt/var/cache/pacman/pkg
mount -o $OPTS,subvol=@db /dev/vda2 /mnt/var/lib/pacman

# Base Install
pacstrap -K /mnt base base-devel linux linux-firmware btrfs-progs git vim networkmanager sudo

# Generate FSTAB
genfstab -U /mnt >> /mnt/etc/fstab

# Add the ".snapshots" management mount
UUID=$(blkid -s UUID -o value /dev/vda2)
mkdir -p /mnt/.snapshots
# we use subvolid=5 to tell Linux we want the absolute root of the disk
echo "UUID=$UUID /.snapshots btrfs subvolid=5,$OPTS 0 0" >> /mnt/etc/fstab

echo "Phase 1 Complete. Entering chroot."

arch-chroot /mnt <<EOF
set -e

# Basic Setup
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch-nix-vm" > /etc/hostname

# Network
systemctl enable NetworkManager

# User Setup
useradd -m -G wheel aiden
echo "aiden:password" | chpasswd  # Set a temp password

# Pre-emptively create the seat group and add the user
groupadd -r seat
usermod -aG seat,video,render aiden

# Ensure the persistent copy gets these changes
cp /etc/{passwd,shadow,group} /persist/etc/

# Add wheel group to sudoers list
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# --- 1. Create the Nuke Hook (Runtime) ---
cat <<HOOK > /usr/lib/initcpio/hooks/erase-my-darlings
run_hook() {
    # Mount the root of the drive
    mkdir -p /mnt-root
    mount -t btrfs -o subvolid=5 /dev/vda2 /mnt-root
    
    # Delete the dirty root
    if [ -d "/mnt-root/@" ]; then
        btrfs subvolume delete /mnt-root/@
    fi
    
    # Restore the blank snapshot
    btrfs subvolume snapshot /mnt-root/@blank /mnt-root/@
    
    umount /mnt-root
}
HOOK

# --- 2. Create the Nuke Hook (Build) ---
cat <<INST > /usr/lib/initcpio/install/erase-my-darlings
build() {
    add_runscript
}
help() {
    cat <<HELPEOF
This hook wipes the root subvolume and restores @blank on boot.
HELPEOF
}
INST

# --- 3. Register the Hook ---
# Must be before 'filesystems'
sed -i 's/HOOKS=(base udev/HOOKS=(base udev erase-my-darlings/' /etc/mkinitcpio.conf

# Build Initramfs
mkinitcpio -P

# Bootloader
bootctl install
cat <<BOOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/vda2) rootflags=subvol=@ rw
BOOT

# --- 4. Persistence Tricks ---
# Create the physical folders in the persist vault
mkdir -p /persist/etc
mkdir -p /persist/var/lib/{networkmanager,bluetooth}
mkdir -p /persist/home/aiden/{.ssh,.config/gh,projects}
chown -R 1000:1000 /persist/home/aiden
chmod 700 /persist/home/aiden/.ssh

# Copy current identify files (so we're not locked out)
cp /etc/{passwd,shadow,group} /persist/etc/
systemd-machine-id-setup
cp /etc/machine-id /persist/etc/machine-id

cat <<FSTAB >> /etc/fstab
# --- SYSTEM IDENTITY ---
/persist/etc/passwd /etc/passwd none bind 0 0
/persist/etc/shadow /etc/shadow none bind 0 0
/persist/etc/group /etc/group none bind 0 0
/persist/etc/machine-id /etc/machine-id none bind 0 0

# --- SYSTEM STATE ---
/persist/var/lib/networkmanager /var/lib/networkmanager none bind 0 0
/persist/var/lib/bluetooth /var/lib/bluetooth none bind 0 0

# --- USER IDENTITY & DEV ---
/persist/home/aiden/.ssh /home/aiden/.ssh none bind 0 0
/persist/home/aiden/.config/gh /home/aiden/.config/gh none bind 0 0
/persist/home/aiden/projects /home/aiden/projects none bind 0 0
FSTAB

echo "Phase 2 Complete. Exiting chroot now."

EOF


# We need to access the top-level subvolume one last time
mount -t btrfs -o subvolid=5 /dev/vda2 /mnt

# NOW we take the snapshot. 
# Since @ is currently mounted and active as /mnt/@, this captures the installed OS.
btrfs subvolume snapshot -r /mnt/@ /mnt/@blank

# Verify it exists
ls /mnt
# Should see: @  @blank  @nix ...

umount /mnt

echo "--- Installation Complete! Reboot and run bootstrap.sh ---"
