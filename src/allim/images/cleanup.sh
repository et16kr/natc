#!/bin/sh
sudo umount partition
sudo losetup -d /dev/loop0
rm -f disk.img
