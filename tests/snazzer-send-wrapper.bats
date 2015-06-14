#!/usr/bin/env bats
# vi:syntax=sh

load "$BATS_TEST_DIRNAME/fixtures.sh"

setup() {
    export PATH=$BATS_TMPDIR/bin:$PATH
    mkdir -p "$BATS_TMPDIR/bin"
    cp "$BATS_TEST_DIRNAME/../snazzer-send-wrapper" "$BATS_TMPDIR/bin/"
    chmod a+x "$BATS_TMPDIR/bin/snazzer-send-wrapper"
    sed -i 's/^\(export PATH=.*\)/#\1 # disabled for tests/g' \
        "$BATS_TMPDIR/bin/snazzer-send-wrapper"
    cp "$BATS_TEST_DIRNAME/data/sudo" "$BATS_TMPDIR/bin/"
}

@test "snazzer-send-wrapper" {
    run ./snazzer-send-wrapper
    [ "$status" = "1" ]
}

@test "sudo -n snazzer --list-snapshots '--all'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "4" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
snazzer
--list-snapshots
--all" ]
}

@test "sudo -n snazzer --list-snapshots '--all' '--force'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n snazzer --list-snapshots '--force'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n snazzer --list-snapshots '--all' 'foo=\" some stuff \"' 'hel'\\\\'' squot '\\\\''lo' 'asd \" dquot \" fgh' 'ap ple' ' bon'\\\\''squot'\\\\''jour' 'there'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    echo "$status" >/tmp/status
    echo "$output" >/tmp/output
    [ "$status" = "0" ]
    [ "$output" = "10" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
snazzer
--list-snapshots
--all
foo=\" some stuff \"
hel' squot 'lo
asd \" dquot \" fgh
ap ple
 bon'squot'jour
there" ]
}

# At some point we decided to error when args are switches, hence ^-prefix
@test "sudo -n snazzer --list-snapshots 'bla' '^--bar' '^--cat=\" someone'\''s dog \"' '^--foo='\''a \"b\" c'\'''" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "7" ]
}

@test "sudo -n snazzer --list-snapshots 'unbalance'd squote'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "99" ]
}

@test "sudo -n snazzer --list-snapshots 'unbalance\"d dquote'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
}

@test "sudo -n btrfs send" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

@test "sudo -n btrfs send '-/subvol/.snapshotz/FOO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/FOO2' '-p' '-/subvol/.snapshotz/FOO1'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/FOO1' '-p' '/subvol/.snapshotz/FOO2' '/subvol/.snapshotz/FOO3'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/FOO1' '/subvol/.snapshotz/FOO2'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/FOO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "4" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
btrfs
send
/subvol/.snapshotz/FOO" ]
}

@test "sudo -n btrfs send '/echo \`ls \"/\"; ls /;\`; ~!@#\$(ls)%^&*()_+-='\\''[]'\\''{}|:<>,./?/.snapshotz/FOO2'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "4" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
btrfs
send
/echo \`ls \"/\"; ls /;\`; ~!@#\$(ls)%^&*()_+-='[]'{}|:<>,./?/.snapshotz/FOO2" ]
}

@test "sudo -n btrfs send -p" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/FOO2' '-p'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/FOO2' '-p' '/subvol/.snapshotz/FOO1'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "6" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
btrfs
send
/subvol/.snapshotz/FOO2
-p
/subvol/.snapshotz/FOO1" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/FOO2' -p '/subvol/.snapshotz/FOO1'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "99" ]
}

@test "sudo -n btrfs send '/echo \`ls \"/\"; ls /;\`; ~!@#\$(ls)%^&*()_+-='\\''[]'\\''{}|:<>,./?/.snapshotz/FOO2' '-p' '/echo \`ls \"/\"; ls /;\`; ~!@#\$(ls)%^&*()_+-='\\''[]'\\''{}|:<>,./?/.snapshotz/FOO1'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "6" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
btrfs
send
/echo \`ls \"/\"; ls /;\`; ~!@#\$(ls)%^&*()_+-='[]'{}|:<>,./?/.snapshotz/FOO2
-p
/echo \`ls \"/\"; ls /;\`; ~!@#\$(ls)%^&*()_+-='[]'{}|:<>,./?/.snapshotz/FOO1" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/F'\\''OO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "4" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
btrfs
send
/subvol/.snapshotz/F'OO" ]
}

@test "sudo -n btrfs send '/subvol/.snapshotz/F'OO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "99" ]
}

# snapshots != snapshotz
@test "sudo -n btrfs send '/subvol/.snapshots/FOO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

# snapshots != snapshotz
@test "sudo -n btrfs send '/subvol/.snapshotz/FOO2' '-p' '/subvol/.snapshots/FOO1'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n grep -srl '^> on foo1-host at ' '/subvol/.snapshotz/.measurements/'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "5" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
grep
-srl
^> on foo1-host at 
/subvol/.snapshotz/.measurements/" ]
}

@test "sudo -n grep -srl '^> on foo1-host at ' '/sub'\\''vol/.snapshotz/.measurements/'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "5" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
grep
-srl
^> on foo1-host at 
/sub'vol/.snapshotz/.measurements/" ]
}

@test "sudo -n grep -srl '^> on foo1-host at ' '/subvol/.snapshotz/.measurements/junk'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

@test "sudo -n grep -srl '-^> on foo1-host at ' '/subvol/.snapshotz/.measurements/'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

@test "sudo -n grep -srl '^> on foo1-host at ' '-/subvol/.snapshotz/.measurements/'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

@test "sudo -n grep -srl '^> on foo1-host at ' '/subvol1/.snapshotz/.measurements/' '/subvol2/.snapshotz/.measurements/'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

# snapshots!=snapshotz
@test "sudo -n grep -srl '^> on foo1-host at ' '/subvol/.snapshots/.measurements/'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

@test "sudo -n cat '/subvol/.snapshotz/.measurements/FOO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "3" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
cat
/subvol/.snapshotz/.measurements/FOO" ]
}

@test "sudo -n cat '/sub'\\''vol/.snapshotz/.measurements/FOO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "3" ]
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=ls_args run snazzer-send-wrapper
    [ "$status" = "0" ]
    [ "$output" = "-n
cat
/sub'vol/.snapshotz/.measurements/FOO" ]
}

@test "sudo -n cat" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

@test "sudo -n cat '-/subvol/.snapshotz/.measurements/FOO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

# .snapshots!=.snapshotz
@test "sudo -n cat '/subvol/.snapshots/.measurements/FOO'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "2" ]
}

@test "sudo -n cat '/subvol/.snapshotz/.measurements/FOO1' '/subvol/.snapshotz/.measurements/FOO2'" {
    SSH_ORIGINAL_COMMAND="$BATS_TEST_DESCRIPTION" F=no_args run snazzer-send-wrapper
    [ "$status" = "98" ]
}

teardown() {
    rm "$BATS_TMPDIR/bin/sudo"
    rm "$BATS_TMPDIR/bin/snazzer-send-wrapper"
    rmdir "$BATS_TMPDIR/bin"
}
