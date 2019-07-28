#!/bin/bash

## Variable Declarations
USERNAME="value"
EDITOR=vim
COUNTRY=GB
ENC_PASS="archlinux"
KEYMAP=uk
HOST_NAME=zangetsu
DEVICE=/dev/nvme0n1
LOCALE="en_GB"
LOCALE_UTF8="${LOCALE}.UTF-8"
LUKS_DEVICE=nvme0n1

## Change root
function arch_chroot() {
   arch-chroot /mnt /bin/bash -c "${1}"
}

## Initialise 
mount -o remount,size=2G /run/archiso/cowspace

## Loadkeys
loadkeys uk

## Connect to internet
#wifi-menu

## Editor
pacman -Sy $EDITOR --noconfirm

## Mirror
#read -p "Setting Mirrors.. Hit Enter"
URL="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&use_mirror_status=on"
tmpfile=$(mktemp --suffix=-mirrorlist)
curl -so ${tmpfile} ${URL}
sed -i 's/^#Server/Server/g' ${tmpfile}
mv  /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
mv  ${tmpfile} /etc/pacman.d/mirrorlist
pacman -Sy pacman-contrib --noconfirm
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
rm /etc/pacman.d/mirrorlist.tmp
chmod +r /etc/pacman.d/mirrorlist
cat /etc/pacman.d/mirrorlist
#read -p "Press Enter"

## Partitioning
#read -p "Partitioning .. Hit Enter"
fdisk -l 
echo "Running blkdiscard. All data will be destroyed!"
blkdiscard $DEVICE
lslbk
#read -p "Press Enter"

parted -s $DEVICE mklabel gpt mkpart primary fat32 1MiB 512MiB mkpart primary ext4 512MiB 100% set 1 boot on
sgdisk -t=1:ef00 $DEVICE
sgdisk -t=2:8e00 $DEVICE

## LUKS Creation
#read -p "Creating LUKS... Hit Enter"
echo -n "$ENC_PASS" | cryptsetup --cipher aes-xts-plain64 --key-size=512 --key-file=- luksFormat --type luks2 ${DEVICE}p2
echo -n "$ENC_PASS" | cryptsetup --allow-discards --persistent --key-file=- open ${DEVICE}p2 cryptlvm
sleep 5

## LVM Creation
#read -p "Creating LVM.. Hit Enter"
pvcreate /dev/mapper/cryptlvm
vgcreate lvm /dev/mapper/cryptlvm

lvcreate -L 8G lvm -n swap
lvcreate -l 100%FREE lvm -n root
sleep 5

## Format paritionsi
#read -p "Formatting partitions ... Hit Enter"
mkfs.ext4 /dev/lvm/root
mkswap /dev/lvm/swap
swapon /dev/lvm/swap
mkfs.fat -F32 ${DEVICE}p1

## Mounting 
#read -p "Mounting ... Hit Enter"
mount /dev/lvm/root /mnt
mkdir /mnt/boot
mount ${DEVICE}p1 /mnt/boot
mount /dev/lvm/root /mnt

## Installing Base System
#read -p "Installing Base System . Hit Enter"
pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt base base-devel parted f2fs-tools net-tools iw wireless_tools wpa_supplicant dialog grub os-prober efibootmgr zsh

## Keymap
#read -p "Installing keymap. Hit Enter"
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

## Generate fstab
#read -p "Installing fstab. Hit Enter"
genfstab -t PARTUUID -p /mnt >> /mnt/etc/fstab

## Hostname
#read -p "Hostname stuff.Hit Enter"  
echo "$HOST_NAME" > /mnt/etc/hostname
arch_chroot "sed -i '/127.0.0.1/s/$/ '${HOST_NAME}'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ '${HOST_NAME}'/' /etc/hosts"

## TimeZone 
#read -p "Installing Timezone. Hit Enter"
arch_chroot "ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime"
arch_chroot "hwclock --systohc --utc"

## Locale
#read -p "Installing locale . Hit Enter"
echo 'LANG="'$LOCALE_UTF8'"' > /mnt/etc/locale.conf
arch_chroot "sed -i 's/#\('${LOCALE_UTF8}'\)/\1/' /etc/locale.gen"
arch_chroot "locale-gen"

## Configure mkinitcpio
#read -p "Installing mkinitcpio. Hit Enter"
sed -i '/^HOOK/s/block/block keymap encrypt/' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOK/s/filesystems/lvm2 filesystems/' /mnt/etc/mkinitcpio.conf
arch_chroot "mkinitcpio -p linux"

## Install Bootloader
#read -p "Installing Bootloader. Hit Enter"
sed -i 's/^GRUB_CMDLINE_LINUX="[^"]*/& cryptdevice=\/dev\/'"${LUKS_DEVICE}"'p2:cryptlvm:allow-discards root_trim=yes acpi_rev_override=1/g'  /mnt/etc/default/grub
arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch --recheck"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
## Fix Grub config changes specifically for XPS 15 grub.efi location. - Done. 
#https://unix.stackexchange.com/questions/69112/how-can-i-use-variables-in-the-lhs-and-rhs-of-a-sed-substitution

# Root passwd
echo "Enter root password"
arch_chroot "passwd"

read -p "Phase 1 Done! Press Enter"
## Phase 2 
clear
echo "Starting Phase 2"
# Enable Multilib
read -p "Enable multilib: Press Enter"
arch_chroot "nano /etc/pacman.conf"
arch_chroot "pacman -Syyy"


# Drivers: GFX and Bluetooth
read -p "Enable driver installations Press Enter"
arch_chroot "pacman -S --noconfirm  xf86-video-intel bumblebee nvidia lib32-virtualgl lib32-nvidia-utils"
arch_chroot "pacman -S --noconfirm  bluez bluez-utils"
arch_chroot "systemctl enable bumbleed"

# Xorg
read -p "Enable Xorg installation Press Enter"
arch_chroot "pacman -S --noconfirm xorg-server xorg-apps xorg-xinit xorg-xkill xorg-xinput xf86-input-libinput xdotool wmctrl xclip mesa"
#libinput-gestures"


# Create new users
read -p "Create new users?"
echo "Creating user $USERNAME..."
arch_chroot "useradd -m $USERNAME -s /bin/zsh"
arch_chroot "passwd $USERNAME"
arch_chroot "gpasswd -a $USERNAME bumblebee"

# DE
read -p "install gnome and desktop manager"
arch_chroot "pacman -S --noconfirm gdm gnome gnome-extra gnome-tweak-tool gpaste gnome-bluetooth networkmanager network-manager-applet pygtk pygtksourceview2 dconf-editor gcolor3 gconf neofetch gnome-software gnome-initial-setup"
arch_chroot "pacman -S --noconfirm deja-dup gedit-plugins gnome-power-manager nautilus-share"
arch_chroot "pacman -Rcsn --noconfirm aisleriot atomix four-in-a-row five-or-more gnome-2048 gnome-chess gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-tetravex gnome-taquin swell-foop hitori iagno quadrapassel lights
off tali"
arch_chroot "systemctl enable gdm"


# Other necessary applications
read -p "install other applications "
arch_chroot "pacman -S --noconfirm  firefox chrome-gnome-shell network-manager"
arch_chroot "pacman -S --noconfirm tmux atom libreoffice-fresh-en-gb"

# Fonts
reap -p "install fonts"
arch_chroot "pacman -S --noconfirm noto-fonts-emoji ttf-roboto ttf-overpass ttf-ibm-plex ttf-hack ttf-liberation ttf-ubuntu-font-family"

# Enable gnome-session for user
#arch_chroot "cp -fv /etc/X11/xinit/xinitrc /home/${USERNAME}/.xinitrc"
#arch_chroot "echo -e exec gnome-session >> /home/${USERNAME}/.xinitrc"
#arch_chroot  "chown -R ${USERNAME}:users /home/${USERNAME}/.xinitrc"

## Enable services
read -p "Enabling services: Press Enter"
arch_chroot "systemctl enable org.cups.cupsd.service"
#systemctl enable libinput-gestures
#systemctl enable undervolt
arch_chroot "systemctl enable bluetooth.service"
arch_chroot "systemctl enable NetworkManager.service"







