#!/bin/bash

set -e

cwd=$(pwd)

# The install script resides in the ../cloud dir.

if [ $OS = "ubuntu" ]; then
    bash "$WWD/cloud/install_docker_ubuntu.sh"
fi

echo "${GREEN}docker is installed !${RESTCOR}"

cd "$cwd"

