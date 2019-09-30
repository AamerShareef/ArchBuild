#!/bin/bash
sudo systemctl start vboxservice.service
sudo modprobe -a vboxdrv vboxnetadp vboxnetflt vboxpci vboxvideo vboxguest
