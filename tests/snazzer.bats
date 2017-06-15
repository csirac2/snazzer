#!/usr/bin/env bats
# vi:syntax=sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

setup() {
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns
    export SNAZZER_DATE=$(date +"%Y-%m-%dT%H%M%S%z")
    export MNT=$(prepare_mnt)
    export SNAZZER_TMP=$BATS_TMPDIR/snazzer-tests
    [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
}

gather_snapshots() {
    su_do find "$MNT" | grep -v '[0-9]/' | grep '[0-9]$'
}

expected_snapshots() {
    [ -n "$MNT" -a -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
    expected_list_subvolumes "$MNT" | sed "s|$|/.snapshotz/$SNAZZER_DATE|g"
}

expected_snapshots_raw() {
    [ -n "$SNAZZER_DATE" ]
    echo "$MNT/.snapshotz/$SNAZZER_DATE"
    gen_subvol_list | sed "s|^|$MNT/|g" | while read SUBVOL; do
        echo "$SUBVOL/.snapshotz/$SNAZZER_DATE"
    done
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

@test "snazzer --version" {
    run snazzer --version
    git_describe_snazzer_version > $(expected_file)
    echo "$output" > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer --all check excludefile syntax" {
    SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns.error
    run snazzer --all --dry-run "$MNT"
    # 12 means that snazzer detected the errors in the file
    [ "$status" = "12" ]
}

@test "snazzer --all [mountpoint]" {
    run snazzer --all "$MNT"
    expected_snapshots | sort > $(expected_file)
    gather_snapshots | sort > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer copies user and group of source" {
    run snazzer --all "$MNT"
    stat "$MNT" --format "%U:%G" > $(expected_file)
    stat "$MNT/.snapshotz" --format "%U:%G" > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer --dry-run --all [mountpoint]" {
    run snazzer --dry-run --all "$MNT"
    [ "$status" = "0" ]
    eval "$output"
    expected_snapshots | sort > $(expected_file)
    gather_snapshots | sort > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer [subvol]" {
    run snazzer "$MNT/home"
    expected_snapshots_raw | grep "^$MNT/home" > $(expected_file)
    gather_snapshots | sort > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

@test "snazzer [subvol1] [subvol2] [subvol3]" {
    run snazzer "$MNT/home" "$MNT/srv" "$MNT/var/cache"
    expected_snapshots_raw | grep "^$MNT/\(home\|srv\|var/cache\)/\.snapshotz" \
        | sort > $(expected_file)
    gather_snapshots | sort > $(actual_file)
    diff -u $(expected_file) $(actual_file)
    [ "$status" = "0" ]
}

teardown() {
    teardown_mnt "$MNT" >/dev/null 2>/dev/null
}
