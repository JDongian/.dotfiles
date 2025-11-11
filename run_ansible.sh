#!/bin/sh
ansible-playbook --ask-become-pass -u root -i inventory -e @custom_vars.yaml ansible/all.yaml
