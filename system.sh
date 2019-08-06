#!/bin/bash

# Run this script after rebooting into DE

# Setting up ZSH and ohmyzsh
echo "Setting up Oh My Zsh!"
rm -rf ~/.oh-my-zsh
curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh > install.sh
chmod +x install.sh
./install.sh
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
cp ./dotfiles/.zshrc ~/
rm install.sh

# Gnome Environment restore
echo "Setting up you Gnome environment!"

dconf load /org/gnome/ < ./gnome/gnome_settings
# eyecandy - themes,icons & cursors
sudo unzip -o -q ./gnome/eyecandy/gtk-themes.zip -d  /usr/share/themes/
sudo unzip -o -q ./gnome/eyecandy/icon-themes.zip -d  /usr/share/icons/
sudo unzip -o -q ./gnome/eyecandy/cursor-themes.zip -d  /usr/share/icons/
# Dash to Panel
( ./gnome/gnome-install.sh --install --extension-id 1160 --system --version latest
# Panel OSD
./gnome/gnome-install.sh --install --extension-id 708 --system --version latest
# Caffeine
./gnome/gnome-install.sh --install --extension-id 517 --system --version latest
# CPU Power Manager
./gnome/gnome-install.sh --install --extension-id 945 --system --version latest
# Simple Net Speed
./gnome/gnome-install.sh --install --extension-id 1085 --system --version latest
# Extended Gestures
./gnome/gnome-install.sh --install --extension-id 1253 --system --version latest
# Status Area Horizontal Spacing
./gnome/gnome-install.sh --install --extension-id 355 --system --version latest
# No workspace switcher popop
./gnome/gnome-install.sh --install --extension-id 758 --system --version latest
# Remove Drop Down Arrows
./gnome/gnome-install.sh --install --extension-id 800 --system --version latest
# Remove Rounded Arrows
./gnome/gnome-install.sh --install --extension-id 448 --system --version latest
)>/dev/null 2>&1

# Making Workspaces
mkdir -p /home/$USER/{space,pwn,notes}
mkdir -p /home/$USER/space/pictures
mkdir -p /home/$USER/space/downloads
mkdir -p /home/$USER/pwn/{binaries/{win,unix},boxes,connect,exploits,opt,vm}
rm -rf /home/$USER/D* /home/$USER/Mus* /home/$USER/Pict* /home/$USER/Vid* /home/$USER/Temp* /home/$USER/Publi*
#echo XDG_DOWNLOAD_DIR=\$HOME/Downloads\
#vim /home/$USER/.config/user-dirs.dirs
sed -i  's/^\([^#]\)/#\1/g' /home/$USER/.config/user-dirs.dirs
sed -i  's/HOME\/Pictures/HOME\/space\/pictures/g' /home/$USER/.config/user-dirs.dirs
sed -i  's/HOME\/Downloads/HOME\/space\/downloads/g' /home/$USER/.config/user-dirs.dirs
sed -i  's/^#XDG_DOWN/XDG_DOWN/g' /home/$USER/.config/user-dirs.dirs
sed -i  's/^#XDG_PIC/XDG_PIC/g' /home/$USER/.config/user-dirs.dirs

########################################################################

# Installing Libinput gestures
#sudo pacman -S xdotool wmctrl
sudo gpasswd -a $USER input
git clone https://github.com/bulletmark/libinput-gestures.git
cd libinput-gestures
sudo make install
cd ..
libinput-gestures-setup autostart
rm -rf libinput-gestures

# Installing Mark Text
wget https://github.com/marktext/marktext/releases/download/v0.15.0-rc.3/marktext-0.15.0-rc.3-x64.tar.gz -O marktext.tar.gz
gunzip marktext.tar.gz
tar xvf marktext.tar
cd ./marktext-*
sudo mkdir /usr/share/marktext
sudo cp -r ./* /usr/share/marktext
sudo ln -s /usr/share/marktext/marktext /usr/bin/marktext
cd ..
rm -rf marktext*

# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay

# Install VMWare Workstation
#pacman -S linux-headers fuse2 gtkmm libcanberra pcsclite --noconfirm --needed
yay vmware-workstation --answerdiff N

# Installing Gaming Setup
#pacman -S steam lutris --noconfirm
yay nvidia-xrun

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
#  bash -c  $(wget -qO- https://git.io/vQgMr)
# Extensions
# http://www.bernaerts-nicolas.fr/linux/76-gnome/345-gnome-shell-install-remove-extension-command-line-script#h2-all-in-one-installation-removal-script
## User directory fix - Nautilus side bar
# https://unix.stackexchange.com/questions/269940/remove-folders-from-left-panel-in-nautilus
# smb services rpcbind nfs services? refer lilo
#undervolt
# Fixing permissions
# chmod -R g-w,o-w ./*
