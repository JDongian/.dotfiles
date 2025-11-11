#!/bin/bash

# ansible-stow
wget https://git.io/fjlZ4
sudo mv fjlZ4 /usr/share/ansible/stow

# ansible-aur
git clone https://github.com/kewlfft/ansible-aur.git ~/.ansible/plugins/modules/aur
