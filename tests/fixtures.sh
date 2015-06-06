#!/bin/sh
su_do() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

gen_subvol_list() {
    for SUBVOL in srv 'srv/s p a c e' home var/cache var/lib/docker/btrfs \
        'echo `ls "/"; ls /;`; ~!@#$(ls)%^&*()_+-='\''[]'\''{}|:<>,./?';
    do echo "$SUBVOL"; done
}

setup_run_img_populate() {
    MNT=$1
    shift
    if [ "$MNT" = "/" ]; then MNT=""; fi
    su_do chown "$USER" "$MNT"
    while read SUBVOL; do
        SUBVOL_PARENT=$(dirname "$SUBVOL")
        SUBVOL_NAME=$(basename "$SUBVOL")
        mkdir -p "$MNT/$SUBVOL_PARENT"
        su_do btrfs subvolume create "$MNT/$SUBVOL"
        su_do chown "$USER" "$MNT/$SUBVOL"
        touch "$MNT/$SUBVOL/${SUBVOL_NAME}_junk"
        if [ "$SUBVOL_PARENT" = "." ]; then
            touch "$MNT/${SUBVOL_NAME}_junk"
        else
            touch "$MNT/${SUBVOL_PARENT}_${SUBVOL_NAME}_junk"
        fi
    done
}

setup_mnt() {
    IMG="$BATS_TMPDIR/btrfs.img"
    MNT="$BATS_TMPDIR/mnt"
    if ! df -T "$MNT" 2>/dev/null | grep "$MNT\$" 2>/dev/null >/dev/null; then
        su_do mkdir "$MNT"
        truncate -s 80M "$IMG"
        su_do mkfs.btrfs "$IMG"
        su_do mount "$IMG" "$MNT"
        gen_subvol_list | setup_run_img_populate "$MNT"
    fi
}

teardown_mnt() {
    IMG="$BATS_TMPDIR/btrfs.img"
    MNT="$BATS_TMPDIR/mnt"
    su_do umount "$MNT"
    rm "$IMG"
    su_do rmdir "$MNT"
}
