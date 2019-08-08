#!/bin/bash
# https://askubuntu.com/questions/474556/hiding-output-of-a-command

## Variable Declarations
HOST_NAME=zangetsu
USERNAME="value"
ENC_PASS="archlinux"
USERPASS=""
ROOTPASS=""

EDITOR=vim
COUNTRY=GB
KEYMAP=uk
DEVICE=/dev/nvme0n1
LOCALE="en_GB"
LOCALE_UTF8="${LOCALE}.UTF-8"
LUKS_DEVICE=nvme0n1
BUILD_DIR=/home/$USERNAME/ArchBuild

## Change root
function arch_chroot() {
   arch-chroot /mnt /bin/bash -c "${1}"
}
clear
echo "Initialising..."
(
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
) > /dev/null 2>&1

## Partitioning
echo "Setting up Drives!"
(
blkdiscard $DEVICE
lsblk
parted -s $DEVICE mklabel gpt mkpart primary fat32 1MiB 512MiB mkpart primary ext4 512MiB 100% set 1 boot on
sgdisk -t=1:ef00 $DEVICE
sgdisk -t=2:8e00 $DEVICE

## LUKS Creation
#read -p "Creating LUKS... Hit Enter"
echo -n "$ENC_PASS" | cryptsetup --cipher aes-xts-plain64 --key-size=256 --key-file=- luksFormat --type luks2 ${DEVICE}p2
echo -n "$ENC_PASS" | cryptsetup --allow-discards --persistent --key-file=- open ${DEVICE}p2 cryptlvm
sleep 2

## LVM Creation
#read -p "Creating LVM.. Hit Enter"
pvcreate /dev/mapper/cryptlvm
vgcreate lvm /dev/mapper/cryptlvm
lvcreate -L 8G lvm -n swap
lvcreate -l 100%FREE lvm -n root
sleep 1

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
) > /dev/null 2>&1

## Installing Base System
echo "Installing Base System"
(
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
sed -i '/127.0.0.1/s/$/ '${HOST_NAME}'/' /mnt/etc/hosts
sed -i '/::1/s/$/ '${HOST_NAME}'/' /mnt/etc/hosts

## TimeZone
#read -p "Installing Timezone. Hit Enter"
arch_chroot "ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime"
arch_chroot "hwclock --systohc --utc"

## Locale
#read -p "Installing locale . Hit Enter"
echo 'LANG="'$LOCALE_UTF8'"' > /mnt/etc/locale.conf
arch_chroot "sed -i 's/#\('${LOCALE_UTF8}'\)/\1/' /etc/locale.gen"
arch_chroot "locale-gen"

# Enable Multilib
#read -p "Enable multilib: Press Enter"
sed -i "/\[multilib\]/,/Include/"'s/^#//' /mnt/etc/pacman.conf
#arch_chroot "nano /etc/pacman.conf"
arch_chroot "pacman -Syyy"

## Configure mkinitcpio
#read -p "Installing mkinitcpio. Hit Enter"
sed -i '/^HOOK/s/block/block keymap encrypt/' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOK/s/filesystems/lvm2 filesystems/' /mnt/etc/mkinitcpio.conf
sed -i 's/^MODULES=(/MODULES=(i915/' /mnt/etc/mkinitcpio.conf
arch_chroot "echo options i915 enable_fbc=1 fastboot=1  enable_guc=2 > /etc/modprobe.d/i915.conf"
arch_chroot "mkinitcpio -p linux"

## Install Bootloader
#read -p "Installing Bootloader. Hit Enter"
sed -i 's/^GRUB_CMDLINE_LINUX="[^"]*/& cryptdevice=\/dev\/'"${LUKS_DEVICE}"'p2:cryptlvm:allow-discards root_trim=yes acpi_rev_override=1/g'  /mnt/etc/default/grub
arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch --recheck"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
## Fix Grub config changes specifically for XPS 15 grub.efi location. - Done.
#https://unix.stackexchange.com/questions/69112/how-can-i-use-variables-in-the-lhs-and-rhs-of-a-sed-substitution
) > /dev/null 2>&1

# Root passwd
echo "Setting Root Password!"
(printf "$ROOTPASS\n$ROOTPASS" | arch-chroot /mnt passwd root) > /dev/null 2>&1
#arch_chroot "passwd"

echo "Phase 1 Done! Press Enter"

###########################################################################################################################################
## Phase 2
#clear
echo "Starting Phase 2"

echo "Installing components..."
(
# Install Microcode
arch_chroot "pacman -S --noconfirm intel-ucode"

# Xorg
#read -p "Enable Xorg installation Press Enter"
arch_chroot "pacman -S --noconfirm xorg-server xorg-apps xorg-xinit xorg-xkill xorg-xinput xf86-input-libinput xdotool wmctrl xclip mesa"

# Basic Tools
arch_chroot "pacman -S --noconfirm bc rsync mlocate bash-completion pkgstats arch-wiki-lite vim git tree tmux stress"
arch_chroot "updatedb"
arch_chroot "pacman -S --noconfirm zip unzip unrar p7zip lzop cpio"
arch_chroot "pacman -S  --noconfirm alsa-utils alsa-plugins"
arch_chroot "pacman -S --noconfirm pulseaudio pulseaudio-alsa"
arch_chroot "pacman -S --noconfirm ntfs-3g dosfstools exfat-utils f2fs-tools fuse fuse-exfat autofs mtpfs"
arch_chroot "pacman -S --noconfirm nfs-utils"
arch_chroot "pacman -S --noconfirm wget samba smbnetfs"
arch_chroot "pacman -S --noconfirm tlp powertop htop"

# DE - GNOME
arch_chroot "pacman -S --noconfirm gnome gnome-tweak-tool gparted gpaste dconf-editor gnome-nettool gnome-usage polari ghex gnome-bluetooth network-manager-applet gcolor3 gconf pygtk pygtksourceview2  nautilus-share gnome-power-manager gedit-plugins chrome-gnome-shell gnome-initial-setup dmenu"
arch_chroot "systemctl enable gdm"
arch_chroot "systemctl enable NetworkManager"

# Other necessary applications
#read -p "install other applications "
arch_chroot "pacman -S --noconfirm firefox"
arch_chroot "pacman -S --noconfirm atom libreoffice-fresh-en-gb"

# Fonts
#read -p "install fonts"
arch_chroot "pacman -S --noconfirm noto-fonts-emoji noto-fonts ttf-roboto otf-overpass ttf-ibm-plex ttf-hack ttf-liberation ttf-ubuntu-font-family fontconfig"

# CUPS
arch_chroot "pacman -S --noconfirm cups cups-pdf"
arch_chroot "systemctl enable org.cups.cupsd.service"

# Drivers: GFX and Bluetooth
#read -p "Enable driver installations Press Enter"
arch_chroot "pacman -S --noconfirm  xf86-video-intel bumblebee bbswitch nvidia lib32-virtualgl lib32-nvidia-utils"
arch_chroot "pacman -S --noconfirm  bluez bluez-utils"
arch_chroot "systemctl enable bluetooth"
) > /dev/null 2>&1

# Create new users
#read -p "Create new users?"
echo "Creating user $USERNAME..."
(arch_chroot "useradd -m -G bumblebee,wheel -s /bin/zsh $USERNAME"
printf "$USERPASS\n$USERPASS" | arch-chroot /mnt passwd $USERNAME
#arch_chroot "passwd $USERNAME"
sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /mnt/etc/sudoers
arch_chroot "systemctl enable bumblebeed"
) >/dev/null 2>&1

####### System installation
# Move files to Arch-Chroot


#Other application dependencies
echo "Setting up last stage...installing other dependencies"
(
cp --recursive ../ArchBuild /mnt$BUILD_DIR
arch_chroot "pacman -S --noconfirm --needed linux-headers fuse2 gtkmm libcanberra pcsclite"
arch_chroot "pacman -S --noconfirm --needed vulkan-icd-loader lib32-vulkan-icd-loader steam lutris"
arch_chroot "pacman -S --noconfirm --needed wine giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups samba"
arch_chroot "pacman -S xdotool wmctrl --noconfirm"
arch_chroot "chown -hR $USERNAME:$USERNAME /home/$USERNAME/"
) >/dev/null 2>&1

echo "Setting up BlackArch Repos.."
arch_chroot "curl -O https://blackarch.org/strap.sh"
arch_chroot "chmod +x ./strap"
arch_chroot "./strap.sh"
arch_chroot "rm ./strap.sh"

echo "Setting up Pwnage TOOLS!"
(
arch_chroot "pacman -S --noconfirm --needed nmap gnu-netcat net-snmp unicornscan masscan netdiscover netcat wireshark-qt tcpdump nbtscan amap knock"
arch_chroot "pacman -S --noconfirm --needed dnsrecon"

arch_chroot "pacman -S --noconfirm --needed responder testssl.sh sslyze"

arch_chroot "pacman -S --noconfirm --needed metasploit exploitdb sploitctl"

arch_chroot "pacman -S --noconfirm --needed nikto cadaver davtest gobuster burpsuite sqlmap wafw00f wpscan dotdotpwn wfuzz w3af dirb dirbuster joomscan wascan"
arch_chroot "pacman -S --noconfirm --needed oscanner tnscmd blackarch/webshells whatweb cewl beef apache droopescan mssqlscan"

#Forensic
arch_chroot "pacman -S --noconfirm --needed blackarch/ntdsxtract"

arch_chroot "pacman -S --noconfirm --needed edb mingw-w64-gcc gdb strace glibc  autoconf libtool nasm"

arch_chroot "pacman -S --noconfirm --needed enum4linux  net-snmp onesixtyone snmpcheck nbtenum snmpenum"

arch_chroot "pacman -S --noconfirm --needed hydra hashcat ncrack medusa hash-identifier blackarch/crackmapexec john pyrit hashid opencl-nvidia crunch smbcrunch community/fcrackzip  multilib/lib32-cracklib"

arch_chroot "pacman -S --noconfirm --needed perl-image-exiftool exiv2 aircrack-ng"
# rpcclient? hyperion? powershell evasion ? hyperion has new version - check it out!
arch_chroot "pacman -S --noconfirm --needed blackarch/veil blackarch/hyperion-crypter blackarch/mimikatz blackarch/rsactftool"

arch_chroot "pacman -S --noconfirm --needed blackarch/windows-privesc-check blackarch/linux-exploit-suggester.sh"

arch_chroot "pacman -S --noconfirm --needed smbclient smbexec smbmap sambascan"

arch_chroot "pacman -S --noconfirm --needed community/sshuttle chisel 3proxy rpivot"
arch_chroot "pacman -S --noconfirm --needed rdesktop postgresql putty community/perl-mail-sendmail exim  proxychains ranger  wine obs-studio tor openvpn community/freerdp rinetd extra/dmidecode community/dos2unix"

arch_chroot "pacman -S --noconfirm --needed wordlistctl"
## Python and python applications
arch_chroot "pacman -S --noconfirm --needed python-pip community/python-pycryptodomex python-click community/python-paramiko python2-paramiko python-scp python2-scp pyinstaller python2-click blackarch/pymssql community/python2-pyftpdlib community/python-pipenv community/python2-pycryptodomex community/python2-gflags"
) > /dev/null 2>&1

## Seclist setup
#wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip  && unzip SecList.zip  && rm -f SecList.zip

echo "Done! Enjoy your arch linux installation!"
# Unmount and reboot
read -p "Unmount and reboot?"
umount -R /mnt
reboot
