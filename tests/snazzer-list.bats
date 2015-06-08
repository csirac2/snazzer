#!/usr/bin/env bats
# vi:syntax=sh

# It's *much* faster to run this via run-tests.sh, but we always want to keep
# these .bats files free of any dependency on run-tests.sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns

# setup/teardown is crazy slow, so skip it here if it's already done
setup() {
    if [ -z "$IMG" ]; then export IMG=$BATS_TMPDIR/btrfs.img; fi
    if [ -z "$MNT" ]; then export MNT=$BATS_TMPDIR/mnt; fi
    if [ "$MNT" != "/tmp/snazzer-tests/mnt" ]; then
        SNAP_LIST_FILE=$(mktemp)
        [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
        if mountpoint -q "$MNT"; then
            teardown_mnt
        fi
        setup_mnt >/dev/null 2>>/dev/null
        setup_snapshots
    fi
}

expected_list_subvolumes_output() {
    NUM_EXCL=2

    expected_list_subvolumes
    cat <<HERE

$NUM_EXCL subvolumes excluded in $MNT by ${SNAZZER_SUBVOLS_EXCLUDE_FILE}.
HERE
}

@test "snazzer --list-subvolumes --all [mountpoint]" {
    run snazzer --list-subvolumes --all "$MNT"
    [ "$status" = "0" ]
    [ "$output" = "$(expected_list_subvolumes_output)" ]
}

expected_list_snapshots_output() {
    NUM_EXCL=2
    cat "$SNAP_LIST_FILE"
    cat <<HERE

$NUM_EXCL subvolumes excluded in $MNT by ${SNAZZER_SUBVOLS_EXCLUDE_FILE}.
HERE
}

@test "snazzer --list-snapshots --all [mountpoint]" {
    run snazzer --list-snapshots --all "$MNT"
    echo "$output" >/tmp/out
    expected_list_snapshots_output >/tmp/exp
    [ "$status" = "0" ]
    [ "$output" = "$(expected_list_snapshots_output)" ]
}

@test "snazzer --list-snapshots --all [mountpoint/subvol]" {
    run snazzer --list-snapshots --all "$MNT/home"
    [ "$status" = "2" ]
}

@test "snazzer --list-snapshots [/subvol1]" {
    run snazzer --list-snapshots "$MNT/home"
    [ "$status" = "0" ]
    [ "$output" = "$(expected_list_snapshots_output | grep "^$MNT/home")" ]
}

@test "snazzer --list-snapshots [/subvol1] [/subvol2] [/subvol3]" {
    run snazzer --list-snapshots "$MNT/home" "$MNT/srv" "$MNT/var/cache"
    [ "$status" = "0" ]
    [ "$(expected_list_snapshots_output | \
        grep "^$MNT/\(home\|srv\|var/cache\)/\.snapshotz" |sort)" = "$output" ]
    
}

# setup/teardown is crazy slow, so skip it here if it's already done
teardown() {
    if [ "$MNT" != "/tmp/snazzer-tests/mnt" ]; then
        rm "$SNAP_LIST_FILE"
        teardown_mnt >/dev/null 2>/dev/null
    fi
}

#trap '_teardown' EXIT
