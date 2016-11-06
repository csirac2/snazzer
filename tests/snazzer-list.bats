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
    readlink -f $BATS_TEST_DIRNAME/../snazzer > $(expected_file)
    readlink -f $(which snazzer) > $(actual_file)
    diff -u $(expected_file) $(actual_file)
}

@test "snazzer --list-subvolumes --all [mountpoint]" {
    run snazzer --list-subvolumes --all "$MNT"
    expected_list_subvolumes_output > $(expected_file)
    echo "$output" > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer --list-snapshots --all [mountpoint]" {
    run snazzer --list-snapshots --all "$MNT"
    expected_list_snapshots_output > $(expected_file)
    echo "$output" > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer --list-snapshots --all [mountpoint/subvol]" {
    run snazzer --list-snapshots --all "$MNT/home"
    [ "$status" = "2" ]
}

@test "snazzer --list-snapshots [/subvol1]" {
    run snazzer --list-snapshots "$MNT/home"
    expected_list_snapshots_output | grep "^$MNT/home" > $(expected_file)
    echo "$output" > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer --list-snapshots [/subvol1] [/subvol2] [/subvol3]" {
    run snazzer --list-snapshots "$MNT/home" "$MNT/srv" "$MNT/var/cache"
    expected_list_snapshots_output | \
        grep "^$MNT/\(home\|srv\|var/cache\)/\.snapshotz" | \
        sort > $(expected_file)
    echo "$output" > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

teardown() {
    teardown_mnt "$MNT" >/dev/null 2>/dev/null
}
