#!/bin/bash

function setup_gnome(){
  echo "[-] Setting up your Gnome workflow"
  dconf load /org/gnome/ < ./gnome/gnome_settings

  sudo unzip -o -q ./gnome/eyecandy/gtk-themes.zip -d  /usr/share/themes/
  sudo unzip -o -q ./gnome/eyecandy/icon-themes.zip -d  /usr/share/icons/
  sudo unzip -o -q ./gnome/eyecandy/cursor-themes.zip -d  /usr/share/icons/

  (
  # Dash to Panel
   ./gnome/gnome-install.sh --install --extension-id 1160 --system --version latest
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
  # Removes Gnome Dash
  ./gnome/gnome-install.sh --install --extension-id 1297 --system --version latest
  # Hide Activities Button
  ./gnome/gnome-install.sh --install --extension-id 1128 --system --version latest
  )>/dev/null 2>&1
  echo "[+] Gnome environment restored!"
}

function setup_zsh(){
  echo "[-] Setting up Zsh"

  rm -rf ~/.oh-my-zsh
  curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh > install.sh
  chmod +x install.sh
  ./install.sh
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions > /dev/null 2>&1
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions > /dev/null 2>&1
  cp ./dotfiles/.zshrc ~/
  rm install.sh
  echo "[+] Zsh setup complete!"

}

function setup_workspace(){
  echo "[-] Creating your workspace $USER!"
  mkdir -p /home/$USER/{void,pwn,space/{notes/{personal,offsec,system},library,projects}}
  mkdir -p /home/$USER/void/{pictures,downloads,videos}
  mkdir -p /home/$USER/pwn/{binaries/{win,unix},boxes/{oscp,htb},connect,exploits/{win,unix},opt,vm}
  rm -rf /home/$USER/D* /home/$USER/Mus* /home/$USER/Pict* /home/$USER/Vid* /home/$USER/Temp* /home/$USER/Publi*

  sed -i  's/^\([^#]\)/#\1/g' /home/$USER/.config/user-dirs.dirs
  sed -i  's/HOME\/Pictures/HOME\/void\/pictures/g' /home/$USER/.config/user-dirs.dirs
  sed -i  's/HOME\/Videos/HOME\/void\/videos/g' /home/$USER/.config/user-dirs.dirs
  sed -i  's/HOME\/Downloads/HOME\/void\/downloads/g' /home/$USER/.config/user-dirs.dirs
  sed -i  's/^#XDG_DOWN/XDG_DOWN/g' /home/$USER/.config/user-dirs.dirs
  sed -i  's/^#XDG_VIDE/XDG_VIDE/g' /home/$USER/.config/user-dirs.dirs
  sed -i  's/^#XDG_PIC/XDG_PIC/g' /home/$USER/.config/user-dirs.dirs
  xdg-user-dirs-update 2>&1
  echo "enabled=False" > /home/$USER/.config/users-dir.conf
  echo "[+] $USER ! Your workspace is now ready"
}

function setup_gestures() {
  echo "[-] Installing Gestures"
  sudo gpasswd -a $USER input
  git clone https://github.com/bulletmark/libinput-gestures.git > /dev/null 2>&1
  cd libinput-gestures
  sudo make install > /dev/null 2>&1
  cd ..
  sudo cp ./dotfiles/libinput-gestures.conf /etc/libinput-gestures.conf
  libinput-gestures-setup autostart
  rm -rf libinput-gestures
  echo "[+] Gestures setup complete!"

}

function setup_undervolt(){

  echo "[-] Installing Undervolt"
  git clone https://github.com/georgewhewell/undervolt.git >/dev/null 2>&1
  cd undervolt
  sudo python ./setup.py build > /dev/null 2>&1
  sudo python ./setup.py install > /dev/null 2>&1
  cd ..
  sudo rm -rf undervolt
  sudo undervolt --core -100 --cache -100 --uncore -100 --analogio -100
  echo "[+] Undervolt installed!"

}

function setup_scripts(){
  echo "[-] Installing VMware Scripts"
  sudo rm -rf /usr/bin/vmware-start.sh >/dev/null 2>&1
  sudo rm -rf /usr/bin/vmware-stop.sh  >/dev/null 2>&1
  chmod +x ./scripts/vmware-st*
  sudo cp ./scripts/vmware-st* /usr/local/bin/
  echo "[-] VMware Scripts Installed"
  echo "[-] Undervolt Scripts"
  sudo rm -rf /usr/bin/undervolt-start.sh >/dev/null 2>&1
  sudo rm -rf /usr/bin/undervolt-stop.sh  >/dev/null 2>&1
  chmod +x ./scripts/undervolt-st*
  sudo cp ./scripts/undervolt-st* /usr/local/bin/
  echo "[+] Undervolt Scripts Installed"
  echo "[-] Installing fix-perm script"
  sudo rm -rf /usr/bin/fix-perm.sh >/dev/null 2>&1
  chmod +x ./scripts/fix-perm.sh
  sudo cp ./scripts/fix-perm.sh /usr/local/bin/
  echo "[+] Scripts Installed"


}

function setup_notes(){
  sudo rm -rf /usr/share/marktext
  sudo rm -rf /usr/bin/marktext
  wget https://github.com/marktext/marktext/releases/download/v0.15.0/marktext-0.15.0-x64.tar.gz -O marktext.tar.gz
  gunzip marktext.tar.gz
  tar xvf marktext.tar
  cd ./marktext-*
  sudo mkdir /usr/share/marktext
  sudo cp -r ./* /usr/share/marktext
  sudo ln -s /usr/share/marktext/marktext /usr/bin/marktext
  cd ..
  rm -rf marktext*
}

function setup_yay(){
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
  yay vmware-workstation --answerdiff N
  yay nvidia-xrun
}

setup_gnome
setup_zsh
setup_workspace
setup_gestures
setup_undervolt
setup_scripts
setup_notes
setup_yay

# Firefox Tweaks
# about:config
# layers.acceleration.force-enabled = true
# Create a new string -> network.security.ports.banned.override add values 1-65535
# Plugins: Foxy Proxy Ublock origin

########## Gnome Things
# Gnome restore saved_settings
# gnome terminal themes https://mayccoll.github.io/Gogh/#0
#  bash -c  $(wget -qO- https://git.io/vQgMr)
## GNOME backup settings
#dconf dump /org/gnome > saved_settings.dconf
#dconf load /org/gnome < saved_settings.dconf
# Extensions
# http://www.bernaerts-nicolas.fr/linux/76-gnome/345-gnome-shell-install-remove-extension-command-line-script#h2-all-in-one-installation-removal-script
## User directory fix - Nautilus side bar
# https://unix.stackexchange.com/questions/269940/remove-folders-from-left-panel-in-nautilus
# smb services rpcbind nfs services? refer lilo
