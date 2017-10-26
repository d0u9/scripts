#!/bin/bash

set -e

version="2.6"

cwd=$(pwd)

# Clone tmux source
cd $GITHUB_DIR
git clone git@github.com:tmux/tmux.git
cd tmux
git checkout 2.6

bash autogen.sh
./configure --prefix=$APPS_CELLAR_DIR/tmux
make -j $CORES
make install

# Create symbol link
rm -fr "$APPS_BIN_DIR/tmux"
cd "$APPS_BIN_DIR"
ln -s ../cellar/tmux/bin/tmux .

# Create Config file
cd "$DOT_DIR"
./install.sh tmux

echo "{GREEN}tmux installed !{RESTCOR}"

cd "$cwd"

