#!/usr/bin/env bats
# vi:syntax=sh

# It's *much* faster to run this via run-tests.sh, but we always want to keep
# these .bats files free of any dependency on run-tests.sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns

# setup/teardown is crazy slow, so skip it here if it's already done
setup() {
    [ -n "$MNT" ]
    if [ "$KEEP_FIXTURES" != "1" ]; then
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

expected_snapshots_raw() {
    [ -n "$SNAZZER_DATE" ]
    gen_subvol_list | sed "s|^|$MNT/|g" | while read SUBVOL; do
        echo "$SUBVOL/.snapshotz/$SNAZZER_DATE"
    done
}

@test "snazzer --all [mountpoint]" {
    export SNAZZER_DATE=$(date +"%Y-%m-%dT%H%M%S%z")
    run snazzer --all "$MNT"
    [ "$status" = "0" ]
    [ "$(expected_snapshots | sort)" = "$(gather_snapshots | sort)" ]
}

@test "snazzer [subvol]" {
    export SNAZZER_DATE=$(date +"%Y-%m-%dT%H%M%S%z")
    run snazzer "$MNT/home"
    [ "$status" = "0" ]
    [ "$(expected_snapshots_raw | grep "^$MNT/home")" = "$(gather_snapshots | sort)" ]
}

@test "snazzer [subvol1] [subvol2] [subvol3]" {
    export SNAZZER_DATE=$(date +"%Y-%m-%dT%H%M%S%z")
    run snazzer "$MNT/home" "$MNT/srv" "$MNT/var/cache"
    [ "$status" = "0" ]
    [ "$(expected_snapshots_raw | \
        grep "^$MNT/\(home\|srv\|var/cache\)/\.snapshotz" | sort)" = \
        "$(gather_snapshots | sort)" ]
}

# setup/teardown is crazy slow, so skip it here if it's already done
teardown() {
    if [ "$KEEP_FIXTURES" != "1" ]; then
        rm "$SNAPS_TEST_FILE"
        teardown_mnt >/dev/null 2>/dev/null
    fi
}

#trap '_teardown' EXIT
