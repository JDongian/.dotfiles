#!/bin/sh
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syy --noconfirm
