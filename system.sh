#!/bin/bash
USERNAME=""

################ Next Phase
# Restore Backups
# [BACKUP] Settings in ~/.config/libinput-gestures.conf
# [BACKUP] Dconf - restore gnome settings
# [BACKUP] Grab zshrc and ohmyzsh files from backup
# [BACKUP] Gnome Extensions
# [BACKUP] Gnome themes, icons and cursors

# Installing Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Installing Libinput gestures
sudo pacman -S xdotool wmctrl
sudo gpasswd -a $USERNAME input
git clone https://github.com/bulletmark/libinput-gestures.git
cd libinput-gestures
sudo make install
cd ..
libinput-gestures-setup autostart
rm -rf libinput-gestures

# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay

# Install VMWare Workstation
sudo pacman -S linux-headers fuse2 gtkmm libcanberra pcsclite
yay vmware-workstation
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



# Gaming Setup
sudo pacman -S steam lutris --noconfirm
yay nvidia-xrun

# smb services rpcbind nfs services? refer lilo
#undervolt
#virtual box and vmware ?

# Customizations - Setting Tweaking
# Dot Files management

## USer directory fix
## Use x11 as default login
# https://unix.stackexchange.com/questions/269940/remove-folders-from-left-panel-in-nautilus
vim ~/.config/user-dirs.dirs

# Fixing permissions
# chmod -R g-w,o-w ./*

# Making Workspaces
cd ~
mkdir -p {space,pwn}
mkdir -p ./space/pictures
mkdir -p ./space/downloads

#Pentest Toolkits
##BlackArch Repos
curl -O https://blackarch.org/strap.sh
chmod +x ./strap.sh
sudo ./strap.sh
rm strap.sh

##Tools based on categorisation
##Tools configuration

#Note Taking Setup
#Marktext

#Automation of Backup and Restoration
## GNOME settings
#dconf dump / > saved_settings.dconf
#dconf load / < saved_settings.dconf

# zshrc ohmyzsh
# Copy zshrc and ohmyzsh files from backup
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Gnome Themes
wget https://github.com/daniruiz/flat-remix-gtk/archive/master.zip
unzip master.zip
cd flat-remix-gtk-master
sudo cp ./* /usr/share/themes/

# Icons
wget https://github.com/OrancheloTeam/oranchelo-icon-theme/archive/v0.8.0.1.tar.gz
tar xvf v0.8.0.1.tar.gz
cd oranchelo-icon-theme-0.8.0.1
sudo cp -r ./* /usr/share/icons/

# Cursor
# Restore eye candy from BACKUP

  ## Gnome Extensions
sudo pacman -S jq
rm -f ./install-gnome-extensions.sh; wget -N -q "https://raw.githubusercontent.com/cyfrost/install-gnome-extensions/master/install-gnome-extensions.sh" -O ./install-gnome-extensions.sh && chmod +x install-gnome-extensions.sh && ./install-gnome-extensions.sh
./install-gnome-extensions.sh -e --file gnome-extensions.txt   

