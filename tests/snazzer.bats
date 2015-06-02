#!/usr/bin/env bats
# vi:syntax=sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

su_do() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

setup_run >/dev/null 2>/dev/null

emit_snazzer_list_subvolumes_expected() {
    cat <<HERE
$BATS_TMPDIR/mnt
$BATS_TMPDIR/mnt/srv
$BATS_TMPDIR/mnt/srv/s p a c e
$BATS_TMPDIR/mnt/home
$BATS_TMPDIR/mnt/echo \`ls "/"; ls /;\`; ~!@#\$(ls)%^&*()_+-='[]'{}|:<>,./?

3 subvolumes excluded in $BATS_TMPDIR/mnt by $SNAZZER_SUBVOLS_EXCLUDE_FILE.
HERE
}

@test "snazzer --list-subvolumes" {
    run snazzer --list-subvolumes --all "$BATS_TMPDIR/mnt"
    [ "$status" = "0" ]
    [ "$output" = "$(emit_snazzer_list_subvolumes_expected)" ]
}

trap 'teardown_run >/dev/null 2>/dev/null' EXIT
