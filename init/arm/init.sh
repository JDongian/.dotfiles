#!/bin/sh
ssh root@10.0.0.11 'sh -s' < init_keyring_populate.sh
ssh root@10.0.0.11 'sh -s' < python.sh
