#!/bin/bash

SS_CONFIG_FILE=/home/doug/.dot/conf/shadowsocks/ss-redir.json

NAME=ss-redir
RUNTIME_DIR=/var/run/$NAME
BACKUP_FILE=$RUNTIME_DIR/iptables.backup
PID_FILE=$RUNTIME_DIR/ss-redir.pid
LOCAL_PORT=$(awk -F '[:," ]{1,}' '$2 ~ /local_port$/{print $3}' $SS_CONFIG_FILE)
SERVER_IP=$(awk -F '[:," ]{1,}' '$2 ~ /server$/{print $3}' $SS_CONFIG_FILE)

# Permission check
if [[ $EUID -ne 0 ]]; then
    echo "Permission denied, should be run as root"
    exit 1
fi

do_start() {
    echo "Connect to $SERVER_IP, local port: $LOCAL_PORT"

    # create new dir in /var/run
    if [ ! -d "$RUNTIME_DIR" ]; then
        echo "Create runtime dir ..."
        mkdir "$RUNTIME_DIR"
    fi

    if kill -0 $(cat $PID_FILE) 2>/dev/null; then
        echo "Already running, if you want to reload, execute $0 restart"
        exit 1
    fi

    echo "Backup iptables rules ..."
    # backup iptables
    iptables-save > $BACKUP_FILE

    echo "Setup iptables ..."
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

    # Start ss-redir
    ss-redir -u -c $SS_CONFIG_FILE -f $PID_FILE

    echo "OK !"
}

do_stop() {
    echo "Stop ..."
    iptables -t nat -F SHADOWSOCKS
    iptables -t nat -D OUTPUT -p tcp -j SHADOWSOCKS
    iptables -t nat -X SHADOWSOCKS
    iptables -t mangle -F SHADOWSOCKS
    iptables -t mangle -D PREROUTING -j SHADOWSOCKS
    #iptables -t mangle -D OUTPUT -j SHADOWSOCKS_MARK
    iptables -t mangle -X SHADOWSOCKS
    #iptables -t mangle -X SHADOWSOCKS_MARK

    echo "Delete route rule ..."
    while ip rule delete from all to all table 100 2>/dev/null
    do true
    done

    echo "Delete route table ..."
    ip route flush table 100

    echo "Stop ss-redir"
    kill -9 $(cat $PID_FILE) 2>/dev/null

    echo "Restore iptables ..."
    iptables-load < $BACKUP_FILE
}

case "$1" in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    restart|force-reload)
        do_stop
        do_start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|force-reload}" >&2
        exit 3
        ;;
esac
