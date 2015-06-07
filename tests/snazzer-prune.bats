#!/usr/bin/env bats
# vi:syntax=sh

# It's *much* faster to run this via run-tests.sh, but we always want to keep
# these .bats files free of any dependency on run-tests.sh
#
# SMELL: These tests assume working snazzer-prune-candidates w/default config

load "$BATS_TEST_DIRNAME/fixtures.sh"

# setup/teardown is crazy slow, so skip it here if it's already done
setup() {
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$BATS_TEST_DIRNAME/data/exclude.patterns

    [ -n "$MNT" ]
    if [ "$KEEP_FIXTURES" != "1" ]; then
        SNAPS_TEST_FILE=$(mktemp)
        [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ]
        if mountpoint -q "$MNT"; then
            teardown_mnt
        fi
        setup_mnt >/dev/null 2>>/dev/null
        setup_snapshots
    fi
}

gather_snapshots() {
    su_do btrfs subvolume list "$MNT" | sed "s|^.*path |$MNT/|g" | \
        grep '\.snapshotz'
}

# reduces a list of snapshot full-paths down to those that should be left after
# a prune operation. snazzer-prune candidates can only handle one set of dates
# (one subvol) at a time, so this takes care of input spanning multiple subvols.
fake_prune() {
    # Dodgy EOF end-of-list hack because code rhs of pipes are in a subshell and
    # thus can't manipulate variables outside of their scope...
    echo "$1
<<<<EOF>>>>" | while read SNAP; do
        # /tmp/snazzer-tests/mnt/.snapshotz/2015-05-02T063103+1100
        SUBVOL=$(echo $SNAP | sed -n "s#^$MNT/\(\(.*\)/\|\)\.snapshotz.*#\2#p")
        if [ "$SNAP" = "<<<<EOF>>>>" ]; then
            echo "$THIS" | snazzer-prune-candidates --invert
        elif [ -z "$INIT" ]; then
            THIS=$SNAP
            LAST=$SUBVOL
            INIT=1
        elif [ "$SUBVOL" = "$LAST" ]; then
            if [ -n "$THIS" ]; then THIS="$THIS
$SNAP"; else THIS=$SNAP; fi
        else
            echo "$THIS" | snazzer-prune-candidates --invert
            THIS=$SNAP
            LAST=$SUBVOL
        fi
    done
}

@test  "snazzer --prune --all [mountpoint]" {
    run snazzer --prune --all "$MNT"
    [ "$status" = "5" ]
}

@test  "snazzer --prune --all --force [mountpoint]" {
    BEFORE=$(gather_snapshots | sort)
    run snazzer --prune --all --force "$MNT"
    [ "$status" = "0" ]
    [ "$(fake_prune "$BEFORE")" = "$(gather_snapshots | sort)" ]
}

@test  "snazzer --prune --all --dry-run [mountpoint]" {
    find "$MNT" > /tmp/find
    BEFORE=$(gather_snapshots | sort)
    run snazzer --prune --all --dry-run "$MNT"
    [ "$status" = "0" ]
    eval "$output" >/dev/null 2>/dev/null
    [ "$(fake_prune "$BEFORE")" = "$(gather_snapshots | sort)" ]
}

@test  "snazzer --prune --force [subvol]" {
    BEFORE=$(gather_snapshots | sort | grep "^$MNT/home/\.snapshotz")
    run snazzer --prune --force "$MNT/home"
    [ "$status" = "0" ]
    echo "$BEFORE" > /tmp/in4
    [ "$(echo "$BEFORE" | snazzer-prune-candidates --invert)" = \
        "$(gather_snapshots | sort | grep "^$MNT/home/\.snapshotz")" ]
}

@test  "snazzer --prune --force [subvol1] [subvol2] [subvol3]" {
    BEFORE=$(gather_snapshots | sort | grep "^$MNT/\(home\|srv\|var/cache\)/\.snapshotz")
    run snazzer --prune --force "$MNT/home" "$MNT/srv" "$MNT"
    [ "$status" = "0" ]
    [ "$(fake_prune "$BEFORE")" = "$(gather_snapshots | sort | \
        grep "^$MNT/\(home\|srv\|var/cache\)/\.snapshotz")" ]
}

# setup/teardown is crazy slow, so skip it here if it's already done
teardown() {
    if [ "$KEEP_FIXTURES" != "1" ]; then
        rm "$SNAPS_TEST_FILE"
        teardown_mnt >/dev/null 2>/dev/null
    fi
}

#trap '_teardown' EXIT
