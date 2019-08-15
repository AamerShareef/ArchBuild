#!/bin/bash

function backup_to_hdd(){

	echo "[-] Starting backup. Backing up all files in home/$USER/* to HDD."
	
	read -p "[!] MIRROR backup operation: This will delete outdated files in the HDD. Ready?"
	rsync --update -raW --progress --delete --exclude={'.cache','.local'.'.msf4','.mozilla','.config'} ~/* /run/media/zenitsu/Backup_Drive/master
	echo "[+] Backup Complete."
}

backup_to_hdd


