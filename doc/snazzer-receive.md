# NAME

snazzer-receive - receive remote snazzer snapshots to current working dir

# SYNOPSIS

    snazzer-receive [--dry-run] host --all [/path/to/btrfs/mountpoint]

    snazzer-receive [--dry-run] host [/remote/subvol1 [/subvol2 [..]]]

# DESCRIPTION

First, **snazzer-receive** obtains a list of snapshots on the remote host. This
is achieved by processing the first non-option positional argument as an ssh
hostname with which to run `snazzer --list-snapshots [args]` remotely, where
\[args\] are all subsequent **snazzer-receive** arguments (such as `--all` or
`/remote/subvol1`).

**snazzer-receive** then iterates through this list of snapshots, recreating a
filesystem similar to that of the remote host's by creating subvolumes and
`.snapshotz` directories where necessary. Missing snapshots are instantiated
directly with `btrfs send` and `btrfs receive`, using `btrfs send -p [parent]`
where possible to reduce transport overhead of incremental snapshots.

Rather than offer ssh user/port/host specifications through **snazzer-receive**,
it is assumed all remote hosts are properly configured through your ssh config
file usually at `$HOME/.ssh/config`.

# OPTIONS

- **--dry-run**: print rather than execute commands that would be run
- **--help**: Brief help message
- **--man**: Full documentation
- **--man-roff**: Full documentation as \*roff output, Eg:

        snazzer --man-roff | nroff -man

- **--man-markdown**: Full documentation as markdown output, Eg:

        snazzer --man-markdown > snazzer-manpage.md

# ENVIRONMENT

# BUGS AND LIMITATIONS

**NOTE 1:** **snazzer-receive** tries to recreate a filesystem similar to that of
the remote host, starting at the current working directory which represents the
root filesystem. If the remote host has a root btrfs filesystem, this means that
the current working directory should itself also be a btrfs subvolume in order
to receive snapshots under ./.snapshotz. However, **snazzer-receive** will be
unable to replace the current working directory with a btrfs subvolume if it
isn't already one.

Therefore, if required, ensure the current working directory is already a btrfs
subvolume prior to running **snazzer-receive** if you need to receive btrfs root.

**NOTE 2:** `snazzer-receive host --all` may process a list of snapshots
spanning multiple separate btrfs filesystems on a remote host, but unless extra
steps are taken they will all be received into the same local filesystem under
the current working directory. If this is not what you want, manually mount
filesystems under the current working directory before running
**snazzer-receive**.

# EXIT STATUS

**snazzer-receive** will abort with an error message printed to STDERR and
non-zero exit status under the following conditions:

- 1. invalid arguments
- 2. `.snapshotz/.incomplete` already exists at a given destination subvolume
- 9. tried to display man page with a formatter which is not installed

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

- 2. document sudo and recommended sudoers files

    The snazzer project has been written with the assumption that most systems
    administrators will not want to run remote ssh commands either from or to the
    root user. When a snazzer script requires root privileges and uid 0 is not
    detected, these commands are prefixed with `sudo`. Example sudoers files to
    restrict which commands are required for sudo operation shall be included at
    some point.

- 3. include restricted wrapper script to be used as ssh forced command

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
