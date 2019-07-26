#!/bin/bash

## Variable Declarations
EDITOR=vim
COUNTRY=GB
PART_ROOT_ENC_PASS="archlinux"
KEYMAP=uk
host_name=zangetsu

## Change root
function arch_chroot() { #{{{
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
read -p "SEtting Mirrors.. Hit Enter"
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
read -p "Press Enter"

## Partitioning 
read -p "Partitioning .. Hit Enter"
DEVICE=/dev/nvme0n1
fdisk -l 
read -p "Press Enter when ready"
umount -R /mnt
sgdisk --zap-all $DEVICE
wipefs -a $DEVICE

PARTITION_BOOT="${DEVICE}p1"
PARTITION_ROOT="${DEVICE}p2"
DEVICE_ROOT="${DEVICE}p2"

parted -s $DEVICE mklabel gpt mkpart primary fat32 1MiB 512MiB mkpart primary ext4 512MiB 100% set 1 boot on
sgdisk -t=1:ef00 $DEVICE
sgdisk -t=2:8e00 $DEVICE

## LUKS Creation
read -p "Creating LUKS... Hit Enter"
echo -n "$PART_ROOT_ENC_PASS" | cryptsetup --cipher aes-xts-plain64 --key-size=512 --key-file=- luksFormat --type luks2 ${DEVICE}p2
##cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random --verify-passphrase luksFormat ${DEVICE}p2
## cryptsetup --allow-discards --persistent
echo -n "$PART_ROOT_ENC_PASS" | cryptsetup --allow-discards --persistent --key-file=- open ${DEVICE}p2 cryptlvm
sleep 5

### LVM Creation
read -p "Creating LVM.. Hit Enter"
pvcreate /dev/mapper/cryptlvm
vgcreate lvm /dev/mapper/cryptlvm

lvcreate -L 8G lvm -n swap
lvcreate -l 100%FREE lvm -n root

sleep 5
### Format paritionsi
read -p "Formatting partitions ... HIt Enter"
mkfs.ext4 /dev/lvm/root
mkswap /dev/lvm/swap
swapon /dev/lvm/swap

mkfs.fat -F32 ${DEVICE}p1

###Mounting 
read -p "Mounting ... Hit Enter"
mount /dev/lvm/root /mnt
mkdir /mnt/boot
mount ${DEVICE}p1 /mnt/boot
mount /dev/lvm/root /mnt

## Installing Base System

read -p "Installing Base System . Hit Enter"
pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt base base-devel parted f2fs-tools net-tools iw wireless_tools wpa_supplicant dialog git grub os-prober efibootmgr zsh


## Keymap

read -p "Installing keymap. Hit Enter"
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

## Generate fstab

read -p "Installing fstab. Hit Enter"
genfstab -t PARTUUID -p /mnt >> /mnt/etc/fstab

## Hostname
read -p "Hostname stuff.Hit Enter"  
echo "$host_name" > /mnt/etc/hostname
arch_chroot "sed -i '/127.0.0.1/s/$/ '${host_name}'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ '${host_name}'/' /etc/hosts"

## TimeZone 

read -p "Installing Timezone. Hit Enter"
arch_chroot "ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime"
arch_chroot "hwclock --systohc --utc"

## Local

read -p "Installing locale . Hit Enter"
LOCALE="en_GB"
LOCALE_UTF8="${LOCALE}.UTF-8"
echo 'LANG="'$LOCALE_UTF8'"' > /mnt/etc/locale.conf
arch_chroot "sed -i 's/#\('${LOCALE_UTF8}'\)/\1/' /etc/locale.gen"
arch_chroot "locale-gen"


## Configure mkinitcpio

read -p "Installing mkinitcpio. Hit Enter"
sed -i '/^HOOK/s/block/block keymap encrypt/' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOK/s/filesystems/lvm2 filesystems/' /mnt/etc/mkinitcpio.conf
arch_chroot "mkinitcpio -p linux"

## Install Bootloader
LUKS_DISK=nvme0n1p2
read -p "Installing Bootloader. Hit Enter"
#sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=\/dev\/'"${DEVICE}p2"':cryptlvm:allow-discards acpi_rev_override=1 root_trim=yes"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/'"${DEVICE}p2"':cryptlvm:allow-discards acpi_rev_override=1 root_trim=yes"/g' /mnt/etc/default/grub
# below works
#sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=\/dev\/'"${LUKS_DISK}"':crypt"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/'"${LUKS_DISK}"':crypt"/g' /mnt/etc/default/grub
# Sed test 1
sed -i 's/^GRUB_CMDLINE_LINUX="[^"]*/& cryptdevice=\/dev\/\${DEVICE}p2:cryptlvm:allow-discards root_trim=yes acpi_rev_override=1/g'  /mnt/etc/default/grub
arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch --recheck"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
## Fix Grub config changes specifically for XPS 15 grub.efi location. - Done. 
