#!/bin/sh
HOST="root@10.0.0.11"
ssh-copy-id "${HOST}"
ssh "${HOST}" 'sh -s' < init_keyring_populate.sh
ssh "${HOST}" 'sh -s' < python.sh
