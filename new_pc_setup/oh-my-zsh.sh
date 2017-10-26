#!/bin/bash

set -e

cwd=$(pwd)

# Install oh-my-zsh
echo "${RED}Please press Ctrl-D when installation complete.${RESTCOR}"
( sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)" ); wait

# Setup oh-my-zsh
cd $DOT_DIR
./install.sh zsh

