#!/bin/bash
sudo systemctl stop vboxservice.service
sudo modprobe -r vboxdrv vboxnetadp vboxnetflt vboxpci vboxvideo vboxguest
