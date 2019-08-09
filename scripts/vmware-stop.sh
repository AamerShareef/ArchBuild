#!/bin/bash
sudo systemctl stop vmware-networks.service
sudo systemctl stop vmware-usbarbitrator.service
sudo systemctl stop vmware-hostd.service
sudo modprobe -r vmw_vmci vmmon
