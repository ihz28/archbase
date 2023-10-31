#!/bin/bash

# Choose hostname
read -p 'hostname: ' hostname
read -p 'username: ' username

# localization and time setting
ln -sf /usr/share/zoneinfo/Australia/Perth /etc/localtime
hwclock --systohc
sed -i '171s/#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo $hostname > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
reflector --country Australia --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy
pacman -Syu


# INSTALL PACKAGES
pacman -S --noconfirm --needed - < fonts_lists.txt
pacman -S --noconfirm --needed - < Base.txt
pacman -S --noconfirm --needed - < Xorg_files.txt


# Setup GRUB bootloader and Nvidia drivers
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
sed -i '6s/"loglevel=3 quiet"/"loglevel=3 quiet nvidia_drm.modeset=1"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
sed -i '7s/()/(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# ADD ROOT & USER
echo "Root password"
passwd
echo
echo "Adding user"
useradd -m -G sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel $username
passwd $username
sed -i '89s/#//' /etc/sudoers

# SETUP ZRAM
echo "[zram0]" > /etc/systemd/zram-generator.conf
echo "zram-size = ram / 2" >> /etc/systemd/zram-generator.conf

# SERVICES
systemctl enable NetworkManager
systemctl enable firewalld
systemctl enable reflector.timer
systemctl enable fstrim.timer
btrfs subvolume set-def 256 /

echo
echo "Setup Complete!!"
reboot
