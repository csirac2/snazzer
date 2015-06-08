#!/usr/bin/env bats
# vi:syntax=sh

# It's *much* faster to run this via run-tests.sh, but we always want to keep
# these .bats files free of any dependency on run-tests.sh

load "$BATS_TEST_DIRNAME/fixtures.sh"


# setup/teardown is crazy slow, so skip it here if it's already done
setup() {
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns
    export SNAZZER_DATE=$(date +"%Y-%m-%dT%H%M%S%z")
    export MNT=$(prepare_mnt)
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

@test "snazzer --all [mountpoint]" {
    run snazzer --all "$MNT"
    [ "$status" = "0" ]
    [ "$(expected_snapshots | sort)" = "$(gather_snapshots | sort)" ]
}

@test "snazzer --dry-run --all [mountpoint]" {
    run snazzer --dry-run --all "$MNT"
    [ "$status" = "0" ]
    eval "$output" >/dev/null 2>/dev/null
    [ "$(expected_snapshots | sort)" = "$(gather_snapshots | sort)" ]
}

@test "snazzer [subvol]" {
    run snazzer "$MNT/home"
    [ "$status" = "0" ]
    [ "$(expected_snapshots_raw | grep "^$MNT/home")" = \
        "$(gather_snapshots | sort)" ]
}

@test "snazzer [subvol1] [subvol2] [subvol3]" {
    run snazzer "$MNT/home" "$MNT/srv" "$MNT/var/cache"
    [ "$status" = "0" ]
    [ "$(expected_snapshots_raw | \
        grep "^$MNT/\(home\|srv\|var/cache\)/\.snapshotz" | sort)" = \
        "$(gather_snapshots | sort)" ]
}

# setup/teardown is crazy slow, so skip it here if it's already done
teardown() {
    teardown_mnt "$MNT" >/dev/null 2>/dev/null
}

#trap '_teardown' EXIT
