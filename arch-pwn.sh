#!/bin/bash

##BlackArch Repos
curl -O https://blackarch.org/strap.sh
chmod +x ./strap.sh
sudo ./strap.sh
rm strap.sh

##Tools based on categorisation
pacman -S --noconfirm --needed nmap gnu-netcat net-snmp unicornscan masscan netdiscover netcat wireshark-qt tcpdump nbtscan amap knock
pacman -S --noconfirm --needed dnsrecon

pacman -S --noconfirm --needed responder testssl.sh sslyze

pacman -S --noconfirm --needed metasploit exploitdb sploitctl

pacman -S --noconfirm --needed nikto cadaver davtest gobuster burpsuite sqlmap wafw00f wpscan dotdotpwn wfuzz w3af dirb dirbuster joomscan wascan
pacman -S --noconfirm --needed oscanner tnscmd blackarch/webshells whatweb cewl beef apache droopescan mssqlscan

#Forensic
pacman -S --noconfirm --needed blackarch/ntdsxtract

pacman -S --noconfirm --needed edb mingw-w64-gcc gdb strace glibc  autoconf libtool nasm

pacman -S --noconfirm --needed enum4linux  net-snmp onesixtyone snmpcheck nbtenum snmpenum

pacman -S --noconfirm --needed hydra hashcat ncrack medusa hash-identifier blackarch/crackmapexec john pyrit hashid opencl-nvidia crunch smbcrunch community/fcrackzip  multilib/lib32-cracklib

pacman -S --noconfirm --needed perl-image-exiftool exiv2 aircrack-ng
# rpcclient? hyperion? powershell evasion ? hyperion has new version - check it out!
pacman -S --noconfirm --needed blackarch/veil blackarch/hyperion-crypter blackarch/mimikatz blackarch/rsactftool

pacman -S --noconfirm --needed blackarch/windows-privesc-check blackarch/linux-exploit-suggester.sh

pacman -S --noconfirm --needed smbclient smbexec smbmap sambascan

pacman -S --noconfirm --needed community/sshuttle chisel 3proxy rpivot
pacman -S --noconfirm --needed rdesktop postgresql putty community/perl-mail-sendmail exim  proxychains ranger  wine obs-studio tor openvpn community/freerdp rinetd extra/dmidecode community/dos2unix

pacman -S --noconfirm --needed wordlistctl


## Python and python applications
pacman -S --noconfirm --needed python-pip community/python-pycryptodomex python-click community/python-paramiko python2-paramiko python-scp python2-scp pyinstaller python2-click blackarch/pymssql community/python2-pyftpdlib community/python-pipenv community/python2-pycryptodomex community/python2-gflags

## Seclist setup
#wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip  && unzip SecList.zip  && rm -f SecList.zip


# Other tools to install
## sendmail.pl - Brandon Zehm
## gpp-decrypt.rb
## wordpwn.py
## pyinstaller with wine for 32 bit applications

# Pwn tools to Configure
## metasploit
