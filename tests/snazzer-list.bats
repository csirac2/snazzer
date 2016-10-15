#!/usr/bin/env bats
# vi:syntax=sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

setup() {
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns
    local TMPDIR="${BATS_TMPDIR:-/tmp}"
    TMPDIR=$TMPDIR/snazzer-tests
    export SNAP_LIST_FILE=$TMPDIR/btrfs-snapshots.list
    export MNT=$(SNAP_LIST_FILE=$SNAP_LIST_FILE prepare_mnt_snapshots)
    [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
}

expected_list_subvolumes_output() {
    NUM_EXCL=2

    expected_list_subvolumes "$MNT"
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

@test "btrfs mkfs.btrfs in PATH" {
    btrfs --help
    mkfs.btrfs --help
}

@test "snazzer in PATH" {
    local THIS_SNAZZER=$(readlink -f $BATS_TEST_DIRNAME/../snazzer)
    local PATH_SNAZZER=$(readlink -f $(which snazzer))
    
    [ -n "$PATH_SNAZZER" ]
    [ -n "$THIS_SNAZZER" ]
    [ "$PATH_SNAZZER" = "$THIS_SNAZZER" ]
}

@test "snazzer --list-snapshots --all [mountpoint]" {
    run snazzer --list-snapshots --all "$MNT"
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

teardown() {
    teardown_mnt "$MNT" >/dev/null 2>/dev/null
}
