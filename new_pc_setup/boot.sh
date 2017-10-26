#!/bin/bash

dir="$(pwd)"

# Software update and install
apt-get update
apt-get upgrade -y
apt-get install -y git zsh gcc g++ automake autoconf curl vim                  \
                   libtool libtool-bin autoconf pkg-config unzip

cd /tmp
git clone https://github.com/d0u9/scripts.git
cd scripts/new_pc_setup

# Run the real setup script
bash setup.sh

cd "$dir"
rm -fr /tmp/scripts

echo "------------------------- Done --------------------------"
