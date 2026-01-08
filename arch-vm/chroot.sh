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
cat <<EOF > /usr/lib/initcpio/hooks/erase-my-darlings
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
EOF

# --- 2. Create the Nuke Hook (Build) ---
cat <<EOF > /usr/lib/initcpio/install/erase-my-darlings
build() {
    add_runscript
}
help() {
    cat <<HELPEOF
This hook wipes the root subvolume and restores @blank on boot.
HELPEOF
}
EOF

# --- 3. Register the Hook ---
# Must be before 'filesystems'
sed -i 's/HOOKS=(base udev/HOOKS=(base udev erase-my-darlings/' /etc/mkinitcpio.conf

# Build Initramfs
mkinitcpio -P

# Bootloader
bootctl install
cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/vda2) rootflags=subvol=@ rw
EOF

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

cat <<EOF >> /etc/fstab
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
EOF

echo "Phase 2 Complete. Exit chroot now."
