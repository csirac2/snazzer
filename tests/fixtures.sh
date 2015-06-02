#!/bin/sh
su_do() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

test_img_write() {
    FILE=$1
    SIZE=$2
    su_do dd if=/dev/urandom of="$FILE" bs="$SIZE" count="1"
}

gen_subvol_list() {
    for SUBVOL in srv 'srv/s p a c e' home etc/secrets var/lib/docker/btrfs \
        var/cache 'echo `ls "/"; ls /;`; ~!@#$(ls)%^&*()_+-='\''[]'\''{}|:<>,./?';
    do echo "$SUBVOL"; done
}

setup_run_img_populate() {
    MNT=$1
    shift
    if [ "$MNT" = "/" ]; then MNT=""; fi
    while read SUBVOL; do
        SUBVOL_PARENT=$(dirname "$SUBVOL")
        SUBVOL_NAME=$(basename "$SUBVOL")
        echo "SUBVOL: $SUBVOL" >> /tmp/food
        echo "SUBVOL_NAME: $SUBVOL_NAME" >> /tmp/food
        echo "SUBVOL_PARENT: $SUBVOL_PARENT" >> /tmp/food
        su_do mkdir -p "$MNT/$SUBVOL_PARENT"
        su_do btrfs subvolume create "$MNT/$SUBVOL"
        test_img_write "$MNT/$SUBVOL/${SUBVOL_NAME}_junk" 500K
        if [ "$SUBVOL_PARENT" = "." ]; then
            test_img_write "$MNT/${SUBVOL_NAME}_junk" 500K
        else
            test_img_write "$MNT/${SUBVOL_PARENT}_${SUBVOL_NAME}_junk" 500K
        fi
    done
}

setup_run() {
    IMG="$BATS_TMPDIR/btrfs.img"
    MNT="$BATS_TMPDIR/mnt"
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns
    if ! df -T "$MNT" | grep "$MNT\$"; then
        su_do mkdir "$MNT"
        truncate -s 80M "$IMG"
        su_do mkfs.btrfs "$IMG"
        su_do mount "$IMG" "$MNT"
        gen_subvol_list | setup_run_img_populate "$MNT"
    fi
}

teardown_run() {
    su_do umount "$MNT"
    rm "$IMG"
    su_do rmdir "$MNT"
}
