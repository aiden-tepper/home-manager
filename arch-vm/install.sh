#!/usr/bin/env bash
set -e

# --- 1. Disk Wipe & Partitioning ---
sgdisk --zap-all /dev/vda
sgdisk --new=1:0:+512M --typecode=1:ef00 /dev/vda
sgdisk --new=2:0:0     --typecode=2:8300 /dev/vda

mkfs.fat -F 32 -n BOOT /dev/vda1
mkfs.btrfs -L ARCH /dev/vda2 -f

# --- 2. Subvolumes ---
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@persist
btrfs subvolume create /mnt/@log
umount /mnt

# --- 3. Mounts ---
OPTS="compress=zstd,noatime"
mount -o $OPTS,subvol=@ /dev/vda2 /mnt
mkdir -p /mnt/{boot,nix,persist,var/log}
mount /dev/vda1 /mnt/boot
mount -o $OPTS,subvol=@nix /dev/vda2 /mnt/nix
mount -o $OPTS,subvol=@persist /dev/vda2 /mnt/persist
mount -o $OPTS,subvol=@log /dev/vda2 /mnt/var/log

# --- 4. Base Install ---
pacstrap -K /mnt base linux linux-firmware btrfs-progs git vim networkmanager sudo
genfstab -U /mnt >> /mnt/etc/fstab

# --- 5. Chroot Configuration ---
arch-chroot /mnt <<'EOF'
set -e
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "arch-nix" > /etc/hostname
systemctl enable NetworkManager

useradd -m -G wheel aiden
echo "aiden:password" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# --- Erase-on-Boot Hook ---
cat <<INST > /usr/lib/initcpio/install/erase-root
build() { add_runscript; }
INST

cat <<HOOK > /usr/lib/initcpio/hooks/erase-root
run_hook() {
    mkdir -p /mnt-root
    mount -o subvolid=5 /dev/disk/by-label/ARCH /mnt-root
    btrfs subvolume delete /mnt-root/@
    btrfs subvolume snapshot /mnt-root/@blank /mnt-root/@
    umount /mnt-root
}
HOOK

sed -i 's/HOOKS=(base udev/HOOKS=(base udev erase-root/' /etc/mkinitcpio.conf
mkinitcpio -P

bootctl install
cat <<BOOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=LABEL=ARCH rootflags=subvol=@ rw
BOOT
EOF

# --- 6. The "Golden" Blank Snapshot ---
mkdir -p /mnt-temp
mount -o subvolid=5 /dev/vda2 /mnt-temp
btrfs subvolume snapshot -r /mnt-temp/@ /mnt-temp/@blank
umount /mnt-temp

echo "Done. Reboot, log in as aiden, and run bootstrap.sh"
