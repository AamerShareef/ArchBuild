#!/bin/bash

## Variable Declarations
HOST_NAME=zangetsu
USERNAME="value"
ENC_PASS="archlinux"
ROOTPASS=""
USERPASS=""

EDITOR=vim
COUNTRY=GB
KEYMAP=uk
DEVICE=/dev/nvme0n1
LOCALE="en_GB"
LOCALE_UTF8="${LOCALE}.UTF-8"
LUKS_DEVICE=nvme0n1
URL="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&use_mirror_status=on"
BUILD_DIR=/home/$USERNAME/ArchBuild
PWN_TOOLS=arch-pwn.sh

function arch_chroot() {
   arch-chroot /mnt /bin/bash -c "${1}"
}

function initialise(){
  clear
  echo "[-] Starting Arch Zero Installation...."
  (
  mount -o remount,size=2G /run/archiso/cowspace
  loadkeys uk
  pacman -Sy $EDITOR --noconfirm
  ) > /dev/null 2>&1
}

function set_mirrors(){
  echo "[-] Generating Mirrors."
  (
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
  ) > /dev/null 2>&1
  echo "[+] Mirrors Configured!"
}

function set_drives(){
## Partitioning
  echo "[-] Setting up Drives"
  (
    blkdiscard $DEVICE
    parted -s $DEVICE mklabel gpt mkpart primary fat32 1MiB 512MiB mkpart primary ext4 512MiB 100% set 1 boot on
    sgdisk -t=1:ef00 $DEVICE
    sgdisk -t=2:8e00 $DEVICE

    echo -n "$ENC_PASS" | cryptsetup --cipher aes-xts-plain64 --key-size=256 --key-file=- luksFormat --type luks2 ${DEVICE}p2
    echo -n "$ENC_PASS" | cryptsetup --allow-discards --persistent --key-file=- open ${DEVICE}p2 cryptlvm

    pvcreate /dev/mapper/cryptlvm
    vgcreate lvm /dev/mapper/cryptlvm
    lvcreate -L 8G lvm -n swap
    lvcreate -l 100%FREE lvm -n root

    mkfs.ext4 /dev/lvm/root
    mkswap /dev/lvm/swap
    swapon /dev/lvm/swap
    mkfs.fat -F32 ${DEVICE}p1

    mount /dev/lvm/root /mnt
    mkdir /mnt/boot
    mount ${DEVICE}p1 /mnt/boot
    mount /dev/lvm/root /mnt
  ) > /dev/null 2>&1
  echo "[+] Drives have now been setup!"
}

function setup_base(){

  echo "[-] Installing Base System"
  (
    pacman -Sy archlinux-keyring --noconfirm
    pacstrap /mnt base base-devel parted f2fs-tools net-tools iw wireless_tools wpa_supplicant dialog grub os-prober efibootmgr zsh
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

    genfstab -t PARTUUID -p /mnt >> /mnt/etc/fstab

    echo "$HOST_NAME" > /mnt/etc/hostname
    sed -i '/127.0.0.1/s/$/ '${HOST_NAME}'/' /mnt/etc/hosts
    sed -i '/::1/s/$/ '${HOST_NAME}'/' /mnt/etc/hosts

    arch_chroot "ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime"
    arch_chroot "hwclock --systohc --utc"

    echo 'LANG="'$LOCALE_UTF8'"' > /mnt/etc/locale.conf
    arch_chroot "sed -i 's/#\('${LOCALE_UTF8}'\)/\1/' /etc/locale.gen"
    arch_chroot "locale-gen"

    sed -i "/\[multilib\]/,/Include/"'s/^#//' /mnt/etc/pacman.conf
    arch_chroot "pacman -Syyy"

    sed -i '/^HOOK/s/block/block keymap encrypt/' /mnt/etc/mkinitcpio.conf
    sed -i '/^HOOK/s/filesystems/lvm2 filesystems/' /mnt/etc/mkinitcpio.conf
    sed -i 's/^MODULES=(/MODULES=(i915/' /mnt/etc/mkinitcpio.conf
    arch_chroot "echo options i915 enable_fbc=1 fastboot=1  enable_guc=2 > /etc/modprobe.d/i915.conf"
    arch_chroot "mkinitcpio -p linux"

    sed -i 's/^GRUB_CMDLINE_LINUX="[^"]*/& cryptdevice=\/dev\/'"${LUKS_DEVICE}"'p2:cryptlvm:allow-discards root_trim=yes acpi_rev_override=1/g'  /mnt/etc/default/grub
    arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch --recheck"
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"

    (printf "$ROOTPASS\n$ROOTPASS" | arch-chroot /mnt passwd root) > /dev/null 2>&1

  ) > /dev/null 2>&1
  echo "[+] Base system installation complete!"
}

function set_rootpass(){
  echo "[-] Setting Root password"
  (printf "$ROOTPASS\n$ROOTPASS" | arch-chroot /mnt passwd root) > /dev/null 2>&1
  echo "[+] Root password now set!"
}

function setup_applications(){
  echo "[-] Setting up applications..."
  (
    arch_chroot "pacman -S --noconfirm intel-ucode"
    arch_chroot "pacman -S --noconfirm xorg-server xorg-apps xorg-xinit xorg-xkill xorg-xinput xf86-input-libinput xdotool wmctrl xclip mesa"

    arch_chroot "pacman -S --noconfirm bc rsync mlocate bash-completion pkgstats arch-wiki-lite vim git tree tmux stress"
    arch_chroot "updatedb"
    arch_chroot "pacman -S --noconfirm zip unzip unrar p7zip lzop cpio"
    arch_chroot "pacman -S  --noconfirm alsa-utils alsa-plugins"
    arch_chroot "pacman -S --noconfirm pulseaudio pulseaudio-alsa"
    arch_chroot "pacman -S --noconfirm ntfs-3g dosfstools exfat-utils f2fs-tools fuse fuse-exfat autofs mtpfs"
    arch_chroot "pacman -S --noconfirm nfs-utils"
    arch_chroot "pacman -S --noconfirm wget samba smbnetfs"
    arch_chroot "pacman -S --noconfirm tlp powertop htop"

    arch_chroot "pacman -S --noconfirm gnome gnome-tweak-tool gparted gpaste dconf-editor gnome-nettool gnome-usage polari ghex gnome-bluetooth network-manager-applet gcolor3 gconf pygtk pygtksourceview2  nautilus-share gnome-power-manager gedit-plugins chrome-gnome-shell gnome-initial-setup dmenu"
    arch_chroot "systemctl enable gdm"
    arch_chroot "systemctl enable NetworkManager"

    arch_chroot "pacman -S --noconfirm firefox"
    arch_chroot "pacman -S --noconfirm atom libreoffice-fresh-en-gb"

    arch_chroot "pacman -S --noconfirm noto-fonts-emoji noto-fonts ttf-roboto otf-overpass ttf-ibm-plex ttf-hack ttf-liberation ttf-ubuntu-font-family fontconfig"

    arch_chroot "pacman -S --noconfirm cups cups-pdf"
    arch_chroot "systemctl enable org.cups.cupsd.service"

    arch_chroot "pacman -S --noconfirm  xf86-video-intel bumblebee bbswitch nvidia lib32-virtualgl lib32-nvidia-utils"
    arch_chroot "pacman -S --noconfirm  bluez bluez-utils"
    arch_chroot "systemctl enable bluetooth"
    arch_chroot "pacman -S xdotool wmctrl --noconfirm"
  ) > /dev/null 2>&1
  echo "[+] Desktop environment and core applications now installed!"
}

function set_user(){
  echo "[-] Setting up new user: $USERNAME..."
  (
    arch_chroot "useradd -m -G bumblebee,wheel -s /bin/zsh $USERNAME"
    printf "$USERPASS\n$USERPASS" | arch-chroot /mnt passwd $USERNAME
    #arch_chroot "passwd $USERNAME"
    sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /mnt/etc/sudoers
    arch_chroot "systemctl enable bumblebeed"
  ) >/dev/null 2>&1
  echo "[+] New Power User: $USERNAME now setup!"
}

function setup_pwntools(){
echo "[-] Setting up Pwn tools"
echo "[-] Installing Packages"
(
echo "Debug: Copying files to "
cp ./$PWN_TOOLS /mnt
arch_chroot "chmod +x arch-pwn.sh"
arch_chroot "./arch-pwn.sh"
) > /dev/null 2>&1
echo "[+] Packages installed!"
echo "[+] Pwn tools setup!"

}

function cleanup(){
  echo "[-] Installing other dependencies"
  (
    cp --recursive ../ArchBuild /mnt$BUILD_DIR
    arch_chroot "pacman -S --noconfirm --needed linux-headers fuse2 gtkmm libcanberra pcsclite"
    arch_chroot "pacman -S --noconfirm --needed vulkan-icd-loader lib32-vulkan-icd-loader steam lutris"
    arch_chroot "pacman -S --noconfirm --needed wine giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups samba"
    arch_chroot "chown -hR $USERNAME:$USERNAME /home/$USERNAME/"
  ) >/dev/null 2>&1
  echo "[+] Arch Zero installation Complete!"
  read -p "[!] Unmount and reboot?"
  umount -R /mnt
  reboot
}


initialise
set_mirrors
set_drives
setup_base
set_rootpass
setup_applications
set_user
setup_pwntools
cleanup
