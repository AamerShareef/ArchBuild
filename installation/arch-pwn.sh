#!/bin/bash

##BlackArch Repos
curl -O https://blackarch.org/strap.sh
chmod +x ./strap.sh
sudo ./strap.sh
rm strap.sh

# Network Tools
sudo pacman -S --noconfirm --needed nmap gnu-netcat net-snmp unicornscan masscan netdiscover netcat wireshark-qt tcpdump nbtscan amap knock
sudo pacman -S --noconfirm --needed dnsrecon
sudo pacman -S --noconfirm --needed enum4linux  net-snmp onesixtyone snmpcheck nbtenum snmpenum
sudo pacman -S --noconfirm --needed smbclient smbexec smbmap sambascan atftp

# Pivoting Tools
sudo pacman -S --noconfirm --needed community/sshuttle chisel 3proxy rpivot

# Exploitation Tools 
sudo pacman -S --noconfirm --needed metasploit exploitdb sploitctl responder

# Web Application Tools
sudo pacman -S --noconfirm --needed testssl.sh sslyze
sudo pacman -S --noconfirm --needed nikto cadaver davtest gobuster burpsuite sqlmap wafw00f wpscan dotdotpwn wfuzz w3af dirb dirbuster joomscan wascan
sudo pacman -S --noconfirm --needed oscanner tnscmd blackarch/webshells whatweb cewl beef apache droopescan mssqlscan dirsearch
# Forensic Tools
sudo pacman -S --noconfirm --needed blackarch/ntdsxtract

# Reverse Engineering Tools
sudo pacman -S --noconfirm --needed edb mingw-w64-gcc gdb strace glibc  autoconf libtool nasm

# Password Attack Tools
sudo pacman -S --noconfirm --needed hydra hashcat ncrack medusa hash-identifier blackarch/crackmapexec john pyrit hashid opencl-nvidia crunch smbcrunch community/fcrackzip  multilib/lib32-cracklib smtp-user-enum

# Wireless Tools
sudo pacman -S --noconfirm --needed perl-image-exiftool exiv2 aircrack-ng

# Post Exploitation Tools
sudo pacman -S --noconfirm --needed blackarch/veil blackarch/hyperion-crypter blackarch/mimikatz blackarch/rsactftool
sudo pacman -S --noconfirm --needed blackarch/windows-privesc-check blackarch/linux-exploit-suggester.sh

# Other Tools
sudo pacman -S --noconfirm --needed rdesktop postgresql putty community/perl-mail-sendmail exim  proxychains ranger  wine obs-studio tor openvpn community/freerdp rinetd extra/dmidecode community/dos2unix

## Python applications
sudo pacman -S --noconfirm --needed python-pip community/python-pycryptodomex python-click community/python-paramiko python2-paramiko python-scp python2-scp pyinstaller python2-click blackarch/pymssql community/python2-pyftpdlib community/python-pipenv community/python2-pycryptodomex community/python2-gflags

sudo pip install pyftpdlib

# Wordlists
echo "[-] Setting up wordlists"
sudo pacman -S --noconfirm --needed wordlistctl
sudo mkdir /usr/share/wordlists
sudo wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O /usr/share/wordlists/SecList.zip
sudo bsdtar -C /usr/share/wordlists/ --strip-components=1 -xvf  /usr/share/wordlists/SecList.zip
sudo rm -rf /usr/share/wordlists/SecList.zip
echo "[+] Wordlists setup completed!"

# Other tools to install
## sendmail.pl - Brandon Zehm
## gpp-decrypt.rb
## wordpwn.py
## pyinstaller with wine for 32 bit applications

# Pwn tools to Configure
## metasploit
# rpcclient? hyperion? powershell evasion ? hyperion has new version - check it out!
