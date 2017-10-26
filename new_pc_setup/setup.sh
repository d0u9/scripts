#!/bin/bash

set -e

# internal variables
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export RESTCOR=$(tput sgr0)
export CORES=$(lscpu | awk '$0 ~ /^CPU\(s\)/{print $2}')
export WWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

python -mplatform | grep -qi 'ubuntu' && os="ubuntu"
python -mplatform | grep -qi 'centos' && os="centos"

export OS=$os

echo "Scripts dir: $WWD"

cd $HOME

# Generate SSH key
if [ ! -f $HOME/.ssh/id_rsa.pub ]; then
    read -p "${RED}E-mail address for ssh-key generation${RESTCOR}: " readvar
    ssh-keygen -t rsa -b 4096 -C "$readvar"
fi

# Waiting for ssh key adding
echo ""
cat $HOME/.ssh/id_rsa.pub
echo ""
read -n 1 -p "${RED}Add the pub key to github, then press [ENTER] to continue${RESTCOR}"

# Clone my repos
git clone git@github.com:d0u9/.dot.git
export DOT_DIR=$HOME/.dot
cd $HOME/.dot

git clone git@github.com:d0u9/conf.git
export CONF_DIR=$DOT_DIR/conf

git clone git@github.com:d0u9/private.git
export PRIVATE_DIR=$DOT_DIR/private

# Install config files
bash -c "sudo $CONF_DIR/tri-install.sh"

# Create necessary dirs
mkdir -p $HOME/Apps/{bin,cellar,lib,share}
export APPS_BIN_DIR=$HOME/Apps/bin
export APPS_CELLAR_DIR=$HOME/Apps/bin

mkdir -p $HOME/GitHub
export GITHUB_DIR=$HOME/GitHub

# Install docker
bash docker.sh

# Install tmux
cd "$WWD"
bash tmux.sh

# Install oh-my-zsh
cd "$WWD"
bash oh-my-zsh.sh


