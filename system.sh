#!/bin/bash

USER="value"
BUILD_DIR=/home/$USER/ArchBuild
function arch_chroot() {
   arch_chroot /mnt /bin/bash -c "${1}"
}

# Move files to Arch-Chroot
cp --recursive ./ArchBuild /mnt$BUILD_DIR

#Debug
arch_chroot "ls -al /home/$USER"
read -p "Debug 1 - Files moved?"

# Gnome Environment restore
arch-chroot "dconf load /org/gnome/ < $BUILD_DIR/gnome/gnome_settings"
# eyecandy - themes,icons & cursors
arch-chroot "unzip $BUILD_DIR/gnome/eyecandy/gtk-themes.zip -d  /usr/share/themes/"
arch-chroot "unzip $BUILD_DIR/gnome/eyecandy/icon-themes.zip -d  /usr/share/icons/"
arch-chroot "unzip $BUILD_DIR/gnome/eyecandy/cursor-themes.zip -d  /usr/share/icons/"
# Dash to Panel
arch-chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 1160 --system --version latest"
# Panel OSD
arch-chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 708 --system --version latest"
# Caffeine
arch-chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 517 --system --version latest"
# CPU Power Manager
arch-chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 945 --system --version latest"
# Simple Net Speed
arch-chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 1085 --system --version latest"
# Extended Gestures
arch-chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 1253 --system --version latest"
# Status Area Horizontal Spacing
arch-chroot  "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 355 --system --version latest"
# No workspace switcher popop
arch_chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 758 --system --version latest"
# Remove Drop Down Arrows
arch_chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 800 --system --version latest"
# Remove Rounded Arrows
arch_chroot "$BUILD_DIR/gnome/gnome-install.sh --install --extension-id 448 --system --version latest"

#Debug
arch_chroot "ls -al /home/$USER"
read -p "Debug 2 - Gnome setup complete?"

# Making Workspaces
arch_chroot "mkdir -p /home/$USER/{space,pwn,notes}"
arch_chroot "mkdir -p /home/$USER/space/pictures"
arch_chroot "mkdir -p /home/$USER/space/downloads"
arch_chroot "mkdir -p /home/$USER/pwn/{binaries/{win,unix},boxes,connect,exploits,opt,vm}"
arch_chroot "rm -rf /home/$USER/D* /home/$USER/Mus* /home/$USER/Pict* /home/$USER/Vid* /home/$USER/Temp* /home/$USER/Publi*"
arch_chroot "echo XDG_DOWNLOAD_DIR=\"$HOME/Downloads\" "
#arch_chroot "vim /home/$USER/.config/user-dirs.dirs"
arch_chroot "sed -i  's/^\([^#]\)/#\1/g' /home/$USER/.config/user-dirs.dirs"
arch_chroot "sed -i  's/HOME\/Pictures/HOME\/space\/pictures/g' /home/$USER/.config/user-dirs.dirs"
arch_chroot "sed -i  's/HOME\/Downloads/HOME\/space\/downloads/g' /home/$USER/.config/user-dirs.dirs"
arch_chroot "sed -i  's/^#XDG_DOWN/XDG_DOWN/g' /home/$USER/.config/user-dirs.dirs"
arch_chroot "sed -i  's/^#XDG_PIC/XDG_PIC/g' /home/$USER/.config/user-dirs.dirs"

#Debug
arch_chroot "ls -al /home/$USER"
arch_chroot "cat /home/$USER/.config/user-dirs.dirs"
read -p "Debug 3 - Workspaces setup complete?"

#set permissions
arch_chroot "chown -hR $USER:$USER /home/$USER/"

#Debug
arch_chroot "ls -al /home/$USER"
read -p "Debug 4 - permissions restored?"

#Other application dependencies
arch_chroot "pacman -S linux-headers fuse2 gtkmm libcanberra pcsclite --noconfirm --needed"
arch_chroot "pacman -S steam lutris --noconfirm --needed"
arch_chroot "pacman -S xdotool wmctrl --noconfirm"

#Debug
arch_chroot "ls -al /home/$USER"
read -p "Debug 5 - Other app dependencies installed?"

read -p "End of test phase 1"

########################################################################

# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay

# Install VMWare Workstation
#arch_chroot "pacman -S linux-headers fuse2 gtkmm libcanberra pcsclite --noconfirm --needed"
yay vmware-workstation

# Installing Libinput gestures
#sudo pacman -S xdotool wmctrl
sudo gpasswd -a $USER input
git clone https://github.com/bulletmark/libinput-gestures.git
cd libinput-gestures
sudo make install
cd ..
libinput-gestures-setup autostart
rm -rf libinput-gestures


# Installing Gaming Setup
#arch_chroot "pacman -S steam lutris --noconfirm"
yay nvidia-xrun

# Installing Mark Text
wget https://github.com/marktext/marktext/releases/download/v0.15.0-rc.3/marktext-0.15.0-rc.3-x64.tar.gz -O marktext.tar.gz
gunzip marktext.tar.gz
tar xvf marktext.tar
cd marktext-0.15.0-rc.3-x64
sudo mkdir /usr/share/marktext
sudo cp -r ./* /usr/share/marktext
sudo ln -s /usr/share/marktext/marktext /usr/bin/marktext
cd ..
rm -rf marktext*

# Setting up ZSH and ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
cp ./dotfiles/.zshrc ~/
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# VMWare start up script
# sudo systemctl start vmware-networks.service
# sudo systemctl start vmware-usbarbitrator.service
# sudo systemctl start vmware-hostd.service
# sudo modprobe -a vmw_vmci vmmon

# Firefox Tweaks
# about:config
# layers.acceleration.force-enabled = true
# Create a new string -> network.security.ports.banned.override add values 1-65535
# Plugins: Foxy Proxy Ublock origin

#Automation of Backup and Restoration
## GNOME settings
#dconf dump / > saved_settings.dconf
#dconf load / < saved_settings.dconf

########## Gnome Things
# Gnome restore saved_settings
# gnome terminal themes https://mayccoll.github.io/Gogh/#0
#  bash -c  "$(wget -qO- https://git.io/vQgMr)"
# Extensions
# http://www.bernaerts-nicolas.fr/linux/76-gnome/345-gnome-shell-install-remove-extension-command-line-script#h2-all-in-one-installation-removal-script
## User directory fix - Nautilus side bar
# https://unix.stackexchange.com/questions/269940/remove-folders-from-left-panel-in-nautilus
# smb services rpcbind nfs services? refer lilo
#undervolt
# Fixing permissions
# chmod -R g-w,o-w ./*
