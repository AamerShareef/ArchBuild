#!/bin/bash

ARCH_BUILD=""

function backup_dotfiles(){
	echo "[-] Starting dotfiles backup."
	cp ~/.zshrc ./dotfiles/.zshrc
	cp /etc/libinput-gestures.conf ./dotfiles/libinput-gestures.conf
	echo "[+] Dotfiles backup complete."

}

function backup_gnome(){
	echo "[-] Starting GNOME backup."
	dconf dump /org/gnome/ > ./gnome/gnome_settings
	#zip -ur ./gnome/eyecandy/gtk-themes.zip /usr/share/themes
	cd /usr/share/themes/
	zip -ur ~/ArchBuild/gnome/eyecandy/gtk-themes.zip  * -x "Adwaita/*" -x "Adwaita-dark/*" -x "Raleigh/*" -x "HighContrast/*" -x "Emacs/*" -x "Default/*"
        cd -
	#cd /usr/share/icons/
	#zip -ur -s 100m ~/ArchBuild/gnome/eyecandy/icon-cursor-themes.zip  * -x "Adwaita/*" -x "default/*" -x "gnome/*" -x "HighContrast/*" -x "hicolor/*" -x "locolor/*" -x "Emacs/*" -x "Default/*"
	#cd -
	echo "[+] GNOME backup complete."

}

backup_dotfiles
backup_gnome
