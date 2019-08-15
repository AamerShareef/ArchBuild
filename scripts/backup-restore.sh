#!/bin/bash

function backup_to_hdd(){

	echo "[-] Starting backup. Backing up all files in home/$USER/* to HDD."
	rsync --update -raW --progress /run/media/zenitsu/Backup_Drive/master/* ~/
	echo "[+] Backup Complete."
	fix-perm.sh
}

backup_to_hdd


