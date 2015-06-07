#!/usr/bin/env bats
# vi:syntax=sh

# It's *much* faster to run this via run-tests.sh, but we always want to keep
# these .bats files free of any dependency on run-tests.sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns

# setup/teardown is crazy slow, so skip it here if it's already done
setup() {
    if [ "$MNT" != "/tmp/snazzer-tests/mnt" ]; then
        SNAPS_TEST_FILE=$(mktemp)
        [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
        if mountpoint -q "$MNT"; then
            teardown_mnt
        fi
        setup_mnt >/dev/null 2>>/dev/null
    fi
}

gather_snapshots() {
    su_do find "$MNT" | grep -v '[0-9]/' | grep '[0-9]$'
}

expected_snapshots() {
    [ -n "$SNAZZER_DATE" ]
    expected_list_subvolumes | while read SUBVOL; do
        echo "$SUBVOL/.snapshotz/$SNAZZER_DATE"
    done
}

@test "snazzer --all [mountpoint]" {
    export SNAZZER_DATE=$(date +"%Y-%m-%dT%H%M%S%z")
    run snazzer --all "$MNT"
    [ "$status" = "0" ]
    [ "$(expected_snapshots | sort)" = "$(gather_snapshots | sort)" ]
}

expected_list_snapshots_output() {
    NUM_EXCL=2
    cat "$SNAPS_TEST_FILE"
    cat <<HERE

$NUM_EXCL subvolumes excluded in $MNT by ${SNAZZER_SUBVOLS_EXCLUDE_FILE}.
HERE
}

# setup/teardown is crazy slow, so skip it here if it's already done
teardown() {
    if [ "$MNT" != "/tmp/snazzer-tests/mnt" ]; then
        rm "$SNAPS_TEST_FILE"
        teardown_mnt >/dev/null 2>/dev/null
    fi
}

#trap '_teardown' EXIT
