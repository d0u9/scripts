#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Permission denied, should be run as root"
    exit 1
fi

# Update Ubuntu packages
apt-get update
apt-get upgrade

# Install packages to allow apt to use a repository over HTTPS
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add dockers stable repository
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update the apt package index
apt-get update

# Install docker
apt-get install docker-ce

