#!/bin/sh
# Kernel update breaks ChromeOS bootloader https://archlinuxarm.org/forum/viewtopic.php?f=47&t=15169
sed -i 's/#IgnorePkg.*/IgnorePkg = linux-armv7-chromebook linux-armv7/g' /etc/pacman.conf
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syy --noconfirm
