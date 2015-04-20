#!/bin/sh
set -e
. /etc/default/snazzer
. /etc/snazzer/receive-config
BACKUP_ROOT=/media/backup/foo

for HOST in host1 host2 host3 host4; do
    echo "Receiving $HOST:"
    if ! sudo test -e "$BACKUP_ROOT/$HOST"; then
        sudo btrfs subvolume create "$BACKUP_ROOT/$HOST"
    fi
    cd "$BACKUP_ROOT/$HOST"
    if [ "$(hostname)" = "$HOST" ]; then
        snazzer-receive -- --all
    else
        snazzer-receive "$HOST" --all
    fi
done
