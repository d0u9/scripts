#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Permission denied, should be run as root"
    exit 1
fi

cwd=$(pwd)

# internal variables
red=$(tput setaf 1)
green=$(tput setaf 2)
restcor=$(tput sgr0)

# Update
apt-get update && apt-get upgrade -y
apt-get install -y jq

# Clone repo
cd /tmp
git clone https://github.com/d0u9/scripts.git
cd scripts
export SCRIPTS_DIR=$(pwd)

# Basic server setup
source "$SCRIPTS_DIR/install_scripts/cloud_basic_setup.sh"

# Install fail2ban
bash "$SCRIPTS_DIR/install_scripts/fail2ban/install_fail2ban.sh"

# Install docker
bash "$SCRIPTS_DIR/install_scripts/install_docker_ubuntu.sh"
usermod -a -G docker $NEWUSER

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create config files
echo -e "\nConfig files will be placed in /etc/trident"
mkdir -p /etc/trident

read -p "${green}Shadowsocks port:${restcor} " ss_port
echo "${green}Shadowsocks password:${restcor}"
read -s ss_pass

read -p "${green}KcpTun port:${restcor} " kcp_port
echo "${green}KcpTun password:${restcor}"
read -s kcp_pass

jq '.server_port='"$ss_port"' | .password="'"$ss_pass"'"' \
    "$SCRIPTS_DIR/install_scripts/ss_server/ss_config_template.json" > /etc/trident/ss_config.json
jq '.target="ss_server:'"$ss_port"'" | .listen=":'"$kcp_port"'" | .key="'"$kcp_pass"'"' \
    "$SCRIPTS_DIR/install_scripts/ss_server/kcp_config_template.json" > /etc/trident/kcp_config.json

# Compose containers
docker network create tri_pri

compose_dir=$(mktemp -d)
sed -e "s/ss_port/$ss_port/g;s/kcp_port/$kcp_port/g" \
    "$SCRIPTS_DIR/one_key_ss/docker-compose.yml" > "$compose_dir/docker-compose.yml"

cd "$compose_dir"
docker-compose up -d


