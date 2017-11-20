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
apt-get install -y jq rng-tools shadowsocks-libev

# Clone repo
cd /tmp
git clone https://github.com/d0u9/scripts.git
cd scripts
export SCRIPTS_DIR=$(pwd)

# Basic server setup
source "$SCRIPTS_DIR/install_scripts/cloud_basic_setup.sh"

# Install fail2ban
bash "$SCRIPTS_DIR/install_scripts/fail2ban/install_fail2ban.sh"

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
    "$SCRIPTS_DIR/one_key_ss/ss_config_template.json" > /etc/trident/ss_config.json
jq '.target="localhost:'"$ss_port"'" | .listen=":'"$kcp_port"'" | .key="'"$kcp_pass"'"' \
    "$SCRIPTS_DIR/one_key_ss/kcp_config_template.json" > /etc/trident/kcp_config.json


# Install kcptun
cd /tmp
kcptun_version="20171113"
wget "https://github.com/xtaci/kcptun/releases/download/v20171113/kcptun-linux-amd64-$kcptun_version.tar.gz" -O kcptun.tar.gz
tar -xf kcptun.tar.gz
mv server_linux_amd64 /usr/bin/kcp-server
mv client_linux_amd64 /usr/bin/kcp-client
cp "$SCRIPTS_DIR/one_key_ss/kcp-server.service" /etc/systemd/system/

# Install SS
cp "$SCRIPTS_DIR/one_key_ss/ss-server.service" /etc/systemd/system/

# Autostart
systemctl daemon-reload
systemctl enable ss-server.service
systemctl enable kcp-server.service

# Start
systemctl start ss-server.service
systemctl start kcp-server.service

