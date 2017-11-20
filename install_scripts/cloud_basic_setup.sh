#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "Permission denied, should be run as root"
    exit 1
fi

# internal variables
red=$(tput setaf 1)
green=$(tput setaf 2)
restcor=$(tput sgr0)

# Create a new user
read -p "${green}Add a new user, select a username:${restcor} " user
grep $user /etc/passwd || useradd -m -s /bin/bash -G sudo "$user"

echo "${green}set new password for user $user.${restcor}"
passwd "$user"

# Add other users
grep public /etc/passwd || useradd -s /usr/sbin/nologin -M -u 5000 -U public
grep blog /etc/passwd || useradd -s /usr/sbin/nologin -M -u 2001 -U blog

# Disable root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd.service

export NEWUSER=$user

