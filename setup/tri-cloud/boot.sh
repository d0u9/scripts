#!/bin/bash

dir="$(pwd)"

# Software update and install
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git zsh gcc g++ automake autoconf curl vim             \
                        libtool libtool-bin autoconf pkg-config unzip          \
                        libevent-dev openssh-server libncurses5-dev            \
                        fail2ban rng-tools

cd /tmp
git clone https://github.com/d0u9/private.git

git clone https://github.com/d0u9/scripts.git

cd private/setup/tri-cloud

# Run the real setup script
bash setup.sh

cd "$dir"
rm -fr /tmp/scripts

echo "------------------------- Done --------------------------"
