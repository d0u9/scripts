#!/bin/bash

rsync_min_version=3.1.1

rsync_version=$(rsync --version | awk '$1=="rsync" && $2=="version" {print $3}')
c=$(printf "$rsync_version\n$rsync_min_version" | sort -V | head -n1)

if [ "$c" != "$rsync_min_version" ]; then
    echo "Please update your rsync"
    exit 1
fi

rsync -avP --delete --info=progress2 /Volumes/U/Photo trident@tri-server:/media/backup_all/VERY_IMPORTANT/
