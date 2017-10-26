#!/bin/bash

dir="$(pwd)"

# Software update and install
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git zsh gcc g++ automake autoconf curl vim             \
                        libtool libtool-bin autoconf pkg-config unzip          \
                        libevent-dev openssh-server

cd /tmp
git clone https://github.com/d0u9/private.git

git clone https://github.com/d0u9/scripts.git

cd private/new_pc_setup

# Run the real setup script
bash setup.sh

cd "$dir"
rm -fr /tmp/scripts

echo "------------------------- Done --------------------------"
