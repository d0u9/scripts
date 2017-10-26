#!/bin/bash

set -e

# internal variables
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export RESTCOR=$(tput sgr0)
export WWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $HOME

# Generate SSH key
read -p "${RED}E-mail address for ssh-key generation${RESTCOR}" readvar
ssh-keygen -t rsa -b 4096 -C "$readvar"

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
export CONF_DIR=$DOT_DIR/private

