#!/bin/sh
set -e

# setup/teardown is crazy slow, so let's just do it once for a given suite..
setup_snazzer() {
    printf "Running fixture group setup for %s..." "$TEST"
    export SNAZZER_SUBVOLS_EXCLUDE_FILE=$(pwd)/data/exclude.patterns
    [ -e "$SNAZZER_SUBVOLS_EXCLUDE_FILE" ] || \
        echo "$SNAZZER_SUBVOLS_EXCLUDE_FILE missing"
    #create_img >/dev/null 2>>/dev/null
    #if [ "$SETUP_SNAPSHOTS" = "1" ]; then snapshot_img; fi
    echo " done."
}

teardown_snazzer() {
    printf "Running fixture group teardown for %s..." "$TEST"
    teardown_mnt >/dev/null 2>/dev/null
    echo " done."
}

setup() {
    TEST=$1

    case "$TEST" in
        *snazzer.bats)
            export SNAZZER_SUBVOLS_EXCLUDE_FILE=$(pwd)/data/exclude.patterns
            ;;
        *snazzer-prune.bats)
            export SNAZZER_SUBVOLS_EXCLUDE_FILE=$(pwd)/data/exclude.patterns
            ;;
        *snazzer-list.bats)
            export SNAZZER_SUBVOLS_EXCLUDE_FILE=$(pwd)/data/exclude.patterns
            ;;
        *) echo "ERROR: unknown test '$TEST'" >&2; exit 1 ;;
    esac
}

teardown() {
    TEST=$1

    case "$TEST" in
        *snazzer.bats) teardown_snazzer ;;
        *snazzer-prune.bats) teardown_snazzer ;;
        *snazzer-list.bats)
            teardown_snazzer
            rm "$SNAP_LIST_FILE"
            ;;
        *) echo "ERROR: unknown test '$TEST'" >&2; exit 1 ;;
    esac
}

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
