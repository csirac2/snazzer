#!/usr/bin/env bats
# vi:syntax=sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

setup() {
    export MNT=$BATS_TMPDIR/mnt
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns
    export SNAPS_TEST_FILE=$(mktemp)
    [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
    if mountpoint -q "$MNT"; then
        teardown_mnt
    fi
    setup_mnt >/dev/null 2>>/dev/null
}

expected_list_subvolumes() {
    echo "$MNT"
    gen_subvol_list | sed "s|^|$MNT/|g" | \
        grep -v -f "$SNAZZER_SUBVOLS_EXCLUDE_FILE"
}

expected_list_subvolumes_output() {
    NUM_EXCL=2

    expected_list_subvolumes
    cat <<HERE

$NUM_EXCL subvolumes excluded in $MNT by ${SNAZZER_SUBVOLS_EXCLUDE_FILE}.
HERE
}

@test "snazzer --list-subvolumes" {
    run snazzer --list-subvolumes --all "$MNT"
    [ "$status" = "0" ]
    [ "$output" = "$(expected_list_subvolumes_output)" ]
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
    DAY=27
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

setup_snapshots() {
    TMP_DATES=$(mktemp)
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

expected_list_snapshots_output() {
    NUM_EXCL=2
    cat "$SNAPS_TEST_FILE"
    cat <<HERE

$NUM_EXCL subvolumes excluded in $MNT by ${SNAZZER_SUBVOLS_EXCLUDE_FILE}.
HERE
}

@test "snazzer --list-snapshots" {
    setup_snapshots
    run snazzer --list-snapshots --all "$MNT"
    [ "$status" = "0" ]
    [ "$output" = "$(expected_list_snapshots_output)" ]
}

#trap 'teardown_mnt >/dev/null 2>/dev/null' EXIT
teardown() {
    rm "$SNAPS_TEST_FILE"
    teardown_mnt >/dev/null 2>/dev/null
}
