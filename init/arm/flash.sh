#!/bin/bash
set -x
DEV="0" # 1 for chromeOS
IMAGE="ArchLinuxARM-armv7-chromebook-latest.tar.gz"

if [ -s "${IMAGE}" ]
then
    echo "using cached Arch image"
else
    curl -LO "http://os.archlinuxarm.org/os/${IMAGE}"
fi
mkdir -p root
mount /dev/mmcblk${DEV}p2 root
rm -rf root/*
tar -xf "${IMAGE}" -C root

dd if=root/boot/vmlinux.kpart of=/dev/mmcblk${DEV}p1

umount root
sync
rmdir root
