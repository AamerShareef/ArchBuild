#!/bin/bash
drive=$(lsblk | grep /run | cut -d "/" -f 5)
function restore_from_hdd(){

	read -p "[-] Restoring backup from HDD - $drive - Make sure to connect only the HDD"
	rsync --update -raW --progress /run/media/zenitsu/$drive/master/ ~/
	echo "[+] Restore Complete."
	/usr/local/bin/fix-perm.sh
}

restore_from_hdd



