#!/bin/bash
function fix_perm(){
  echo "[-] Fixing permissions for files."
  echo "[-] Run this after copying files over HDD."
	chown -hR $USER:$USER ~/*
	chmod -R 755 ~/*
  echo "[+] Permissions fixed. "

}

fix_perm
