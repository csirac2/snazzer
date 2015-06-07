#!/bin/sh
set -e

init() {
    export MNT=/tmp/snazzer-tests/mnt
    export IMG=/tmp/snazzer-tests/btrfs.img
    export SNAPS_TEST_FILE=$(mktemp)
    mkdir -p "$MNT"
}

# setup/teardown is crazy slow, so let's just do it once for a given suite..
setup_snazzer() {
    printf "Running fixture group setup for %s..." "$TEST"
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$(pwd)/data/exclude.patterns
    [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ] || \
        echo "$SNAZZER_SUBVOLS_EXCLUDE_FILE missing"
    if mountpoint -q "$MNT" 2>/dev/null || [ -e "$IMG" ]; then
        printf " [and tearing down $MNT from previous run] "
        teardown_mnt
    fi
    setup_mnt >/dev/null 2>>/dev/null
    if [ "$SETUP_SNAPSHOTS" = "1" ]; then setup_snapshots; fi
    echo " done."
}

teardown_snazzer() {
    printf "Running fixture group teardown for %s..." "$TEST"
    rm "$SNAPS_TEST_FILE"
    teardown_mnt >/dev/null 2>/dev/null
    echo " done."
}

setup() {
    TEST=$1

    case "$TEST" in
        *snazzer.bats)
            export KEEP_FIXTURES=0
            export SNAZZER_SUBVOLS_EXCLUDE_FILE=$(pwd)/data/exclude.patterns
            ;;
        *snazzer-list.bats)
            export KEEP_FIXTURES=1
            SETUP_SNAPSHOTS=1 setup_snazzer
            ;;
        *) echo "ERROR: unknown test '$TEST'" >&2; exit 1 ;;
    esac
}

teardown() {
    TEST=$1

    case "$TEST" in
        *snazzer.bats) teardown_snazzer ;;
        *snazzer-list.bats) teardown_snazzer ;;
        *) echo "ERROR: unknown test '$TEST'" >&2; exit 1 ;;
    esac
}

init
. "$(pwd)/fixtures.sh"

EXIT=0
if [ -n "$1" ]; then
    setup "$1"
    bats "$@" || EXIT=$?
    teardown "$1"
else
    for TEST in *.bats; do
        setup "$TEST"
        bats "$TEST" || EXIT=$?
        teardown "$TEST"
    done
fi

exit "$EXIT"
