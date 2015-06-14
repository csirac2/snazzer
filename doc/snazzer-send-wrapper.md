# NAME

snazzer-send-wrapper - ssh forced command wrapper for snazzer-receive

# SYNOPSIS

    SSH_ORIGINAL_COMMAND="sudo -n snazzer --list-snapshots '--all'" \
      ./snazzer-send-wrapper

    SSH_ORIGINAL_COMMAND="sudo -n grep -srl \
      'sendinghost1' '/some/.snapshotz/.measurements/'" snazzer-send-wrapper

    SSH_ORIGINAL_COMMAND="sudo -n btrfs send \
      '/some/.snapshotz/2015-04-01T000000Z'" snazzer-send-wrapper

    SSH_ORIGINAL_COMMAND="sudo -n cat \
      '/some/.snapshotz/.measurements/2015-04-01T000000Z'" snazzer-send-wrapper

# OPTIONS

- **--help**: Brief help message
- **--man**: Full documentation
- **--man-roff**: Full documentation as \*roff output, Eg:

        snazzer --man-roff | nroff -man

- **--man-markdown**: Full documentation as markdown output, Eg:

        snazzer --man-markdown > snazzer-manpage.md

# DESCRIPTION

This is a wrapper script to be used in place of a real login shell (Eg. as an
ssh(1) forced command) in order to restrict the commands available to the user
account used by **snazzer-receive** to run `btrfs send`. It may be utilized by
adding an entry in the `~/.ssh/authorized_keys` file on the sending host (Eg.
`sendinghost1`) under the user account used by **snazzer-receive** to run
`btrfs send`.  `~/.ssh/authorized_keys`:

    command="/usr/bin/snazzer-send-wrapper",no-port-forwarding, \
        no-X11-forwarding,no-pty ssh-rsa AAAA...snip...== my key

And then (as an example) receive btrfs snapshots from this `sendinghost1`:

    snazzer-receive sendinghost1 --all

# ENVIRONMENT

- SSH\_ORIGINAL\_COMMAND

    This variable holds the original remote ssh command to be acted upon.

# BUGS AND LIMITATIONS

- This script tries too hard to parse normal shell commands

    A better design would be custom command tokens issued with more easily parsed
    string and argument delimeters. This would require some changes to
    **snazzer-receive**.

    A mitigating factor is that all commands are executed in the form of:

        foo "$@"

    Rather than any variant of the more exciting:

        foo $BAREWORD_ARGUMENTS

    or

        eval "$SSH_ORIGINAL_COMMAND"

    This wrapper script is also sanity-checked with bats regression tests which
    check that only the correct number of arguments, valid arguments, switches,
    path patterns and escape characters are dealt with - anything else is rejected. 

# EXIT STATUS

**snazzer-send-wrapper** will abort with an error message printed to STDERR and
non-zero exit status under the following conditions:

- 2. the command string was not recognized
- 98. the command string was recognized but the arguments were not safe
- 99. the command string was recognized and an attempt was made to
parse/re-pack the arguments however the argument string had dangling quotes or
otherwise confused the parser/"$@" unpacker

# SEE ALSO

snazzer-receive

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
