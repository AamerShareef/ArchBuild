#!/bin/bash
drive=$(lsblk | grep /run | cut -d "/" -f 5)
function backup_to_hdd(){
	echo "[-] Starting backup. Backing up all files in home/$USER/* to $drive HDD. Make sure to connect only one HDD"	
	read -p "[!] MIRROR backup operation: This will delete outdated files in the HDD. Ready?"
	rsync --update -raW --progress --delete  --exclude '.bash*' --exclude '.cache' --include '.config/inkdrop'  --exclude '.esd*' --exclude '.local' --exclude '.oh-my-zsh' --exclude '.pki' --exclude '.wget*' --exclude '.zcomp*' ~/ /run/media/zenitsu/$drive/master
	echo "[+] Backup Complete."
}

backup_to_hdd
