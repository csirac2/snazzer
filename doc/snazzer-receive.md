# NAME

snazzer-receive - receive remote snazzer snapshots to current working dir

# SYNOPSIS

Receive snapshots from remote host via ssh:

    snazzer-receive [--dry-run] host --all [/path/to/btrfs/mountpoint]

    snazzer-receive [--dry-run] host [/remote/subvol1 [/subvol2 [..]]]

Receive snapshots from local filesystem:

    snazzer-receive [--dry-run] -- --all [/path/to/btrfs/mountpoint]

    snazzer-receive [--dry-run] -- /local/subvol1 [/subvol2 [..]]

# DESCRIPTION

First, **snazzer-receive** obtains a list of snapshots to be received by running
`snazzer --list-snapshots [args]`, where \[args\] are all **snazzer-receive**
arguments after the hostname or `--` separator argument.

If the first non-option positional argument is `--`,
`snazzer --list-snapshots [args]` is executed locally and \[args\] will refer to
local filesystem paths. Otherwise, it is taken to mean an ssh hostname which is
used to run the `snazzer --list-snapshots [args]` command remotely, and \[args\]
will refer to paths on that remote host.

**snazzer-receive** then iterates through this list of snapshots recreating a
filesystem similar to the source by creating subvolumes and `.snapshotz`
directories where necessary. Missing snapshots are instantiated directly with
`btrfs send` and `btrfs receive`, using `btrfs send -p [parent]` where
possible to reduce transport overhead of incremental snapshots.

Rather than offer ssh user/port/host specifications through **snazzer-receive**,
it is assumed all remote hosts are properly configured through your ssh config
file usually at `$HOME/.ssh/config`.

# OPTIONS

- **--dry-run**: print rather than execute commands that would be run
- **--help**: Brief help message
- **--man**: Full documentation
- **--man-roff**: Full documentation as \*roff output, Eg:

        snazzer-receive --man-roff | nroff -man

- **--man-markdown**: Full documentation as markdown output, Eg:

        snazzer-receive --man-markdown > snazzer-manpage.md

# ENVIRONMENT

## sudo requirements for sender/remote hosts

**snazzer-receive** assumes the ssh user (or local user, if receiving a local
filesystem) which will be running `btrfs send` (among other things) has
passwordless sudo for the commands it needs to run. Only a few commands are
necessary, the following lines in `/etc/sudoers` or `/etc/sudoers.d/snazzer`
should suffice (replace "sendinguser" with the actual username you will use):

    sendinguser ALL=(root:nobody) NOPASSWD: /usr/bin/snazzer --list-snapshots *
    sendinguser ALL=(root:nobody) NOPASSWD:NOEXEC: \
        /bin/grep -srl */.snapshotz/.measurements/, \
        /sbin/btrfs send */.snapshotz/*, \
        /bin/cat */.snapshotz/.measurements/*

## sudo and cron user requirements for receiving hosts

For interactive use of **snazzer-receive**, a typical user with full sudo
permissions should work out of the box.

For scripted use such as a cron job, or interactive use in more restrictive
environments - running ssh as the root user is generally considered a bad idea.
A dedicated non-root user will require at minimum the following lines in
`/etc/sudoers` or `/etc/sudoers.d/snazzer` (replace "receiveruser" with the
actual username your cron job will use, and remove `NOPASSWD:` if this is for
an interactive/shell user):

    receiveruser ALL=(root:nobody) NOPASSWD:NOEXEC: \
      /usr/bin/test -e */.snapshotz*, \
      /sbin/btrfs subvolume show *, \
      /bin/ls */.snapshotz, \
      /bin/grep -srL */.snapshotz/.measurements/, \
      /bin/mkdir --mode=0755 */.snapshotz, \
      /bin/mkdir --mode=0755 */.snapshotz/.measurements, \
      /bin/mkdir --mode=0755 */.snapshotz/.incomplete, \
      /sbin/btrfs receive */.snapshotz/.incomplete, \
      /sbin/btrfs subvolume create *, \
      /sbin/btrfs subvolume snapshot -r */.snapshotz/.incomplete/* */.snapshotz/,\
      /sbin/btrfs subvolume delete */.snapshotz/.incomplete/*, \
      /bin/rmdir */.snapshotz/.incomplete, \
      /bin/mkdir -vp *, \
      /bin/mkdir --mode=0755 -vp */.snapshotz, \
      /usr/bin/tee -a */.snapshotz/.measurements/*

# SECURITY CONSIDERATIONS

## Remote hosts

**snazzer-receive** relies on running ssh remote commands. It is agnostic about
the auth method used, but this documentation assumes key-based.

Combined with passwordless sudo, remote hosts are vulnerable to and must have
absolute trust in the ssh key-holder, user and host running **snazzer-receive**.

Your deployment should include or consider the following steps, among others not
listed here, to attempt to reduce the impact of or slow down an attacker which
has gained control of the **snazzer-receive** user accounts or ssh keys:

- Protect ssh keys

    The ssh key used to authenticate **snazzer-receive** typically has passwordless
    sudo for `btrfs send` (among other things) and you should assume that whomever
    wields it has access to everything:

    - Avoid passphraseless ssh keyfiles

        This should be obvious: once an attacker has copied such a keyfile they no
        longer need the compromised host to authenticate, and you will have a bigger,
        more urgent job searching for malicious use (and key removal from machines
        which trusted it).

    - Avoid ssh private keyfiles

        Even passphrase-protected keyfiles are vulnerable to keyloggers and
        memory scraping. Consider using smartcards, TPMs, Yubikeys or GoldKeys etc. to
        at least force an attacker to depend on whichever machine has the authentication
        device attached.

        This is especially important when passphrase-protected keyfiles are not
        practical (eg. scripted use of **snazzer-receive** such as cron).

    - Use the timeout option if using an ssh-agent

- Grant minimal sudo rights

    Refer to "sudo requirements for remote hosts". Don't give the **snazzer-receive**
    user the option to run arbitrary commands remotely as root.

- `~/.ssh/authorized_keys`: specify a forced-command/shell-wrapper

    Even if sudo is locked down, don't give the **snazzer-receive** user the option
    of running arbitrary commands remotely. Use a shell wrapper which permits only
    the required sudo commands.
    TODO: provide example
    TODO: Document shell wrapper

    NOTE: This does not prevent data exfiltration via `sudo btrfs send`, but
    may slow down an attacker who would abuse the account in other ways.

- `~/.ssh/authorized_keys`: restrict originating IP address

    Use the `from` option to limit which machine the **snazzer-receive** host's ssh
    key may connect from. This might force an attacker to still depend on the
    **snazzer-receive** host even if they have obtained the private key somehow.
    TODO: provide example
    TODO: link to a guide on this

- Disable interactive shells/logins

    Reduce opportunities for the **snazzer-receive** user to run arbitrary commands;
    remove the account password. NOTE: this doesn't stop ssh remote commands.
    TODO: link to a guide on this

- Log remote ssh commands

    Most distros do zero logging of remote ssh commands. Logging such commands may
    be your only way to spot abuse of the **snazzer-receive** account. The
    `snazzer-send-wrapper` uses `logger -p user.info [cmd]` to log commands on
    remote hosts which are invoking `btrfs send`.
    TODO: link to a guide on this

# BUGS AND LIMITATIONS

**NOTE:** **snazzer-receive** tries to recreate a filesystem similar to that of
the remote host, starting at the current working directory which represents the
root filesystem. If the remote host has a root btrfs filesystem, this means that
the current working directory should itself also be a btrfs subvolume in order
to receive snapshots under ./.snapshotz. However, **snazzer-receive** will be
unable to replace the current working directory with a btrfs subvolume if it
isn't already one.

Therefore, if required, ensure the current working directory is already a btrfs
subvolume prior to running **snazzer-receive** if you need to receive btrfs root.

# EXIT STATUS

**snazzer-receive** will abort with an error message printed to STDERR and
non-zero exit status under the following conditions:

- 1. invalid arguments
- 2. `.snapshotz/.incomplete` already exists at a given destination subvolume
- 9. tried to display man page with a formatter which is not installed
- 12. remote ssh sudo command failed

# TODO

- 1. improve fetch/append of remote host's measurements

    **snazzer-receive** currently does some clumsy concatenation of the remote host's
    measurement file onto the local measurement file for a given snapshot if the
    local measurement file is either missing or does not mention that remote host's
    hostname. Whilst this supports the simple use-case of wanting to obtain initial
    measurements performed on a remote host, once a remote host's measurements have
    been appended there is no attempt to append any further measurement results onto
    the local measurements file.  If this bothers you, please report detailed
    use-cases to the author (patches welcome).

- 2. include restricted wrapper script to be used as ssh forced command

    The snazzer project assumes that systems administrators would prefer to restrict
    the possible exposure of a dedicated snazzer remote user account, even if sudo
    is locked down. To that end, a wrapper script shall be provided which restricts
    possible ssh remote commands to only the few actually necessary for snazzer
    operation.

    Even so, commands which snazzer relies on such as `sudo btrfs send` are
    extremely dangerous no matter if it's the only command allowed by the system -
    securing ssh keys is of utmost importance; consider protecting ssh keys with
    smartcards, TPM, hardware OTP solution such as Yubi/GoldKeys etc.

# SEE ALSO

snazzer, snazzer-measure, snazzer-prune-candidates

# AUTHOR

Paul Harvey <csirac2@gmail.com>, https://github.com/csirac2/snazzer

# LICENSE AND COPYRIGHT

Copyright (c) 2015, Paul Harvey <csirac2@gmail.com> All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1\. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2\. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
