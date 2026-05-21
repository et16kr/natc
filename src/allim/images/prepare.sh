#!/bin/sh
dd if=/dev/zero of=./disk.img bs=2048 count=1024
sudo losetup -o 32256 /dev/loop0 disk.img 
sudo mkfs /dev/loop0
sudo mount -o loop /dev/loop0 ./partition
sudo chown `whoami` partition
