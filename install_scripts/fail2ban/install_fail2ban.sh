#!/bin/bash

set -e

# Get the path of this script
wwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $EUID -ne 0 ]]; then
    echo "Permission denied, should be run as root"
    exit 1
fi

# Install fail2ban
apt-get update
apt-get install -y fail2ban

cp "$wwd/jail.local" "/etc/fail2ban/jail.local"
systemctl daemon-reload
systemctl restart fail2ban.service


