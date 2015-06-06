#!/bin/sh

if [ -z "$IMG" ]; then IMG=$BATS_TMPDIR/btrfs.img; fi
if [ -z "$MNT" ]; then MNT=$BATS_TMPDIR/mnt; fi

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
    local MNT="$1"
    shift
    if [ "$MNT" = "/" ]; then MNT=""; fi
    su_do chown "$USER" "$MNT"
    while read SUBVOL; do
        local SUBVOL_PARENT="$(dirname "$SUBVOL")"
        local SUBVOL_NAME="$(basename "$SUBVOL")"
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
    if ! df -T "$MNT" 2>/dev/null | grep "$MNT\$" 2>/dev/null >/dev/null; then
        su_do mkdir -p "$MNT"
        truncate -s 80M "$IMG"
        su_do mkfs.btrfs "$IMG"
        su_do mount "$IMG" "$MNT"
        gen_subvol_list | setup_run_img_populate "$MNT"
    fi
}

teardown_mnt() {
    if mountpoint -q "$MNT" 2>/dev/null; then
        su_do umount "$MNT"
    fi
    rm -f "$IMG"
}

gen_snapshot_dates() {
    cat <<HERE
2012-01-01T003355+1000
2012-11-21T192011+1000
2013-01-01T072323+1000
2014-01-02T012458+1000
2015-01-01T063321+1000
2015-01-31T063049+1000
2015-02-01T063103+1000
2015-02-28T063103+1000
2015-03-01T063103+1000
2015-03-31T063103+1000
2015-04-01T063103+1000
2015-04-02T063103+1000
2015-04-03T063103+1000
2015-04-04T063103+1000
HERE
    local DAY=27
    while [ "$DAY" != "31" ]; do
        printf "2015-04-%02iT063103+1100\n" "$DAY"
        DAY=$(( DAY + 1 ))
    done
    DAY=01
    while [ "$DAY" != "3" ]; do
        printf "2015-05-%02iT063103+1100\n" "$DAY"
        DAY=$(( DAY + 1 ))
    done
}

expected_list_subvolumes() {
    echo "$MNT"
    gen_subvol_list | sed "s|^|$MNT/|g" | \
        grep -v -f "$SNAZZER_SUBVOLS_EXCLUDE_FILE"
}

setup_snapshots() {
    local TMP_DATES="$(mktemp)"
    gen_snapshot_dates >"$TMP_DATES"

    expected_list_subvolumes | while read SUBVOL; do
        mkdir -p "$SUBVOL/.snapshotz"
        while read DATE <&6; do
            su_do btrfs subvolume snapshot -r "$SUBVOL" \
                "$SUBVOL/.snapshotz/$DATE" >/dev/null
            if [ -n "$SNAPS_TEST_FILE" ]; then
                echo "$SUBVOL/.snapshotz/$DATE" >>"$SNAPS_TEST_FILE"
            fi
        done 6<"$TMP_DATES"
    done

    rm "$TMP_DATES"
}
