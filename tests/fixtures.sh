#!/usr/bin/env sh
set -e

su_do() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Print "0.0.1" from "v0.0.1-2-g4cb93f4"
git_describe_snazzer_version() {
    git describe --tags | sed -n 's/v\?\([0-9.]*\).*/\1/p'
}

gen_subvol_list() {
    for SUBVOL in /srv '/srv/s p a c e' /home /var/cache /var/lib/docker/btrfs \
        'echo `ls "/"; ls /;`; ~!@#$(ls)%^&*()_+-='\''[]'\''{}|:<>,./?' \
        tmp_thing;
    do echo "$SUBVOL"; done
}

# As gen_subvol_list(), but filtered with exclude.patterns applied
gen_subvol_list_excluded() {
    for SUBVOL in /srv '/srv/s p a c e' /home \
        'echo `ls "/"; ls /;`; ~!@#$(ls)%^&*()_+-='\''[]'\''{}|:<>,./?' \
        tmp_thing;
    do echo "$SUBVOL"; done
}

populate_mnt() {
    local MNT="$1"
    [ -n "$MNT" ]
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

create_img() {
    local IMG="$1"
    local TMPDIR="${BATS_TMPDIR:-/tmp}"
    TMPDIR=$TMPDIR/snazzer-tests
    local MNT=$TMPDIR/btrfs.working.mnt
    [ -n "$MNT" -a -n "$IMG" ]
    mkdir -p "$MNT"
    if df -T "$MNT" 2>/dev/null | grep "$MNT\$" 2>/dev/null >/dev/null; then
        umount "$MNT"
    fi
    truncate -s 200M "$IMG"
    # rm .img if mkfs fails because create_img is skipped when it already exists
    su_do mkfs.btrfs "$IMG" || rm "$IMG"
    su_do mount "$IMG" "$MNT"
    gen_subvol_list | populate_mnt "$MNT"
    if [ "$DO_SNAPSHOTS" = "1" ]; then
        snapshot_mnt "$MNT" >/dev/null 2>/dev/null;
    fi
    su_do umount "$MNT"
}

_prepare_mnt() {
    local TMPDIR="${BATS_TMPDIR:-/tmp}"
    TMPDIR=$TMPDIR/snazzer-tests
    if [ "$DO_SNAPSHOTS" = "1" ]; then
        local NAME=btrfs
    else
        local NAME=btrfs-snapshots
    fi
    local MNT="$TMPDIR/${NAME}.working.mnt"
    local WRK="$TMPDIR/${NAME}.working.img"
    local IMG="$TMPDIR/${NAME}.img"
    teardown_mnt "$MNT"
    mkdir -p "$MNT"
    if [ ! -e "$IMG" ]; then
        create_img "$IMG" >/dev/null 2>/dev/null
    fi
    cp "$IMG" "$WRK"
    mkdir -p "$MNT"
    su_do mount "$WRK" "$MNT"
    echo "$MNT"
}

prepare_mnt() {
    DO_SNAPSHOTS=0 _prepare_mnt "$@"
}

prepare_mnt_snapshots() {
    DO_SNAPSHOTS=1 _prepare_mnt "$@"
}

teardown_mnt() {
    local MNT="$1"
    local IMG=$(mount |sed -n "s|^\\(.*\\) on $MNT.*|\1|p")
    [ -n "$MNT" ]
    if mountpoint -q "$MNT" 2>/dev/null; then
        su_do umount "$MNT"
        rmdir "$MNT"
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
    local MNT="$1"
    [ -n "$MNT" -a -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
    echo "$MNT"
    gen_subvol_list_excluded | sed "s|^|$MNT/|g"
}

snapshot_mnt() {
    local MNT="$1"
    [ -n "$MNT" ]
    local TMP_DATES="$(mktemp)"
    gen_snapshot_dates >"$TMP_DATES"

    expected_list_subvolumes "$MNT" | while read SUBVOL; do
        mkdir -p "$SUBVOL/.snapshotz"
        while read DATE <&6; do
            su_do btrfs subvolume snapshot -r "$SUBVOL" \
                "$SUBVOL/.snapshotz/$DATE" >/dev/null 2>/dev/null
            if [ -n "$SNAP_LIST_FILE" ]; then
                echo "$SUBVOL/.snapshotz/$DATE" >>"$SNAP_LIST_FILE"
            fi
        done 6<"$TMP_DATES"
    done

    rm "$TMP_DATES"
}

expected_file() {
    echo "$BATS_TMPDIR/snazzer-tests/$(basename \
        $BATS_TEST_FILENAME)_${BATS_TEST_NUMBER}${1}.expected"
}

actual_file() {
    echo "$BATS_TMPDIR/snazzer-tests/$(basename \
        $BATS_TEST_FILENAME)_${BATS_TEST_NUMBER}${1}.actual"
}
