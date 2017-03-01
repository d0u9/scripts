#!/bin/bash

progname=$0
name=ss-redir
runtime_dir=/run/$name
iptables_bkfile=$runtime_dir/iptables.backup
pid_file=$runtime_dir/$name.pid


SS_CONFIG_FILE=/home/doug/.dot/conf/shadowsocks/ss-redir.json

NAME=ss-redir
RUNTIME_DIR=/var/run/$NAME
BACKUP_FILE=$RUNTIME_DIR/iptables.backup
PID_FILE=$RUNTIME_DIR/ss-redir.pid
LOCAL_PORT=$(awk -F '[:," ]{1,}' '$2 ~ /local_port$/{print $3}' $SS_CONFIG_FILE)
SERVER_IP=$(awk -F '[:," ]{1,}' '$2 ~ /server$/{print $3}' $SS_CONFIG_FILE)

# Print usage
function usage() {
   cat <<EOF
Usage: $progname -f <config_file> {start|stop|status}
EOF
   exit 0
}

# Check user's permission
function check_permission() {
    if [[ $EUID -ne 0 ]]; then
        echo "Permission denied, should be run as root"
        exit 1
    fi
}

# Check input parameter
function check_parameter() {
    [ -f $config_file ] || { echo "ERR: Can't find config file"; exit 1; }
}

# Setup iptables rules
function iptables_up() {
    # setup iptables
    # Create new chain
    iptables -t nat -N SHADOWSOCKS
    iptables -t mangle -N SHADOWSOCKS
    #iptables -t mangle -N SHADOWSOCKS_MARK

    # Ignore your shadowsocks server's addresses
    # It's very IMPORTANT, just be careful.
    iptables -t nat -A SHADOWSOCKS -d $SERVER_IP -j RETURN

    # Ignore LANs and any other addresses you'd like to bypass the proxy
    # See Wikipedia and RFC5735 for full list of reserved networks.
    # See ashi009/bestroutetb for a highly optimized CHN route list.
    iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A SHADOWSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A SHADOWSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A SHADOWSOCKS -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A SHADOWSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A SHADOWSOCKS -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A SHADOWSOCKS -d 240.0.0.0/4 -j RETURN

    # Anything else should be redirected to shadowsocks's local port
    iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports $LOCAL_PORT

    # Add any UDP rules
    ip route add local default dev lo table 100 2>/dev/null
    ip rule add fwmark 1 lookup 100

    iptables -t mangle -A SHADOWSOCKS -p udp --dport 53 -j TPROXY --on-port $LOCAL_PORT --tproxy-mark 0x01/0x01
    iptables -t mangle -A SHADOWSOCKS -p udp --dport 53 -j MARK --set-mark 1
    #iptables -t mangle -A SHADOWSOCKS_MARK -p udp --dport 53 -j MARK --set-mark 1

    # Apply the rules
    iptables -t nat -A OUTPUT -p tcp -j SHADOWSOCKS
    iptables -t mangle -A PREROUTING -j SHADOWSOCKS
    #iptables -t mangle -A OUTPUT -j SHADOWSOCKS
    #iptables -t mangle -A OUTPUT -j SHADOWSOCKS_MARK
}

# Restore iptables rules
function iptables_down() {
    iptables -t nat -F SHADOWSOCKS
    iptables -t nat -D OUTPUT -p tcp -j SHADOWSOCKS
    iptables -t nat -X SHADOWSOCKS
    iptables -t mangle -F SHADOWSOCKS
    iptables -t mangle -D PREROUTING -j SHADOWSOCKS
    #iptables -t mangle -D OUTPUT -j SHADOWSOCKS_MARK
    iptables -t mangle -X SHADOWSOCKS
    #iptables -t mangle -X SHADOWSOCKS_MARK

    # Delete route table
    while ip rule delete from all to all table 100 2>/dev/null; do
        :
    done
    ip route flush table 100
}

function do_status() {
    if [ -f $pid_file ]; then
        pid=$(cat $pid_file)
        echo "Running pid = $pid"
    else
        echo "Not running"
    fi
}

function do_start() {
    if [ -f $pid_file ]; then
        echo "ERR: Already running..."
        exit 1
    fi

    ss_port=$(awk -F '[:," ]{1,}' '$2 ~ /local_port$/{print $3}' $config_file)
    ss_ip=$(awk -F '[:," ]{1,}' '$2 ~ /server$/{print $3}' $config_file)

    # crate run time dir
    if [ ! -d $runtime_dir ]; then
        mkdir -p $runtime_dir
    fi

    iptables-save > $iptables_bkfile

    iptables_up

    ss-redir -u -c $config_file -f $pid_file
}

function do_stop() {
    if [ ! -f $pid_file ]; then
        echo "ERR: Not running..."
        exit 1
    fi

    # kill process
    kill $(cat $pid_file) 2>/dev/null || { echo "stop unsuccessful"; exit 1; }
    rm -fr $pid_file

    iptables_down

    # Restore iptables rules
    iptables-restore < $iptables_bkfile
}

##
# main
##

while getopts ":f:h" opt; do
   case $opt in

   f )  config_file=$OPTARG ;;
   h )  usage ;;
   \?)  usage ;;
   esac
done

shift $(($OPTIND - 1))

check_permission
check_parameter

case $1 in
    "start"  ) do_start ;;
    "stop"   ) do_stop ;;
    "status" ) do_status ;;
    *) usage ;;
esac

