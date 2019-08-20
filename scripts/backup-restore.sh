#!/bin/bash

function restore_from_hdd(){

	echo "[-] Restoring backup from HDD"
	rsync --update -raW --progress /run/media/zenitsu/Backup_Drive/master/ ~/
	echo "[+] Restore Complete."
	/usr/local/bin/fix-perm.sh
}

restore_from_hdd


