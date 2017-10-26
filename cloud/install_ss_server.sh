#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Permission denied, should be run as root"
    exit 1
fi

progname=$0

function usage () {
   cat <<EOF
Usage: $progname [options] -c ss_config_file -k kcp_config_file
  -h    show this help message and exit
  -c    shadowsocks client config file
  -k    kcptun client config file
  -n    container name, default: ss_server
  -m    path to docker command, default: which docker
  -p    ss port to be published, default is 8388
  -u    kcp port to be published, default is 4000
  -t    network the container connect to, default is bridge
EOF
   exit 0
}

[ "$#" = "0" ] && usage

while getopts ":h:c:k:n:t:p:u" opt; do
    case $opt in
       c )  ss_config_file=$(realpath $OPTARG) ;;
       k )  kcp_config_file=$(realpath $OPTARG) ;;
       n )  container_name=$OPTARG ;;
       m )  docker_path=$OPTARG ;;
       t )  net=$OPTARG ;;
       p )  ss_port=$OPTARG ;;
       u )  kcp_port=$OPTARG ;;
       h )  echo "found $opt" ; usage ;;
       \?)  usage ;;
    esac
done

docker_path=${docker_path:-$(which docker)}
container_name=${container_name:-"ss_server"}
net=${net:-"bridge"}
ss_port=${ss_port:-"8388"}
kcp_port=${kcp_port:-"4000"}

if [ ! -f $ss_config_file ] || [ ! -f $kcp_config_file ]; then
    echo "Can't find configuration file, $config_file or $kcp_config_file"
    exit 1
fi

if ! hash $docker_path 2>/dev/null; then
    echo "Can't find $docker_path command, install docker first"
    exit 1
fi

# Install jq
if ! hash jq 2>/dev/null; then
    apt-get update -y && apt-get install -y jq
fi

# Parameter init
sport=$(jq '.server_port' $ss_config_file)
kport=$(jq '.listen' $kcp_config_file | grep -o -P '\d+')

# Pull image from dockerhub
docker pull d0u9/shadowsocks-libev

$docker_path run \
    --name $container_name \
    --hostname $container_name \
    --network $net \
    -d \
    -m 256M \
    --memory-swap -1 \
    -e CMD=server \
    -e ENABLE_KCP=yes \
    -e SS_CONFIG_FILE=/ss.json \
    -v $ss_config_file:/ss.json:ro \
    -e KCP_CONFIG_FILE=/kcp.json \
    -v $kcp_config_file:/kcp.json:ro \
    -p $ss_port:$sport \
    -p $kcp_port:$kport/udp \
    d0u9/shadowsocks-libev

# Auto start for systemd
if [ ! -f /etc/docker-$container_name.service ]; then
    cat << EOF > /etc/systemd/system/docker-$container_name.service
[Unit]
Description=ss-local client powered by shadowscoks-libev
Requires=docker.service
After=docker.service
[Service]
Restart=always
ExecStart=$docker_path start -a $container_name
ExecStop=$docker_path stop -t 2 $container_name
[Install]
WantedBy=default.target
EOF

    if [ "$?" != "0" ]; then
        echo "ERROR: can't write docker-$container_name.service file"
        exit 1
    fi
fi
