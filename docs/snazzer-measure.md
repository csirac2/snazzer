# NAME

snazzer-measure - report shasums & PGP signatures of content under a given path,
along with commands to reproduce or verify data is unchanged

# SYNOPSIS

    snazzer-measure /measured/path [/reported/path] >> path_measurements

# DESCRIPTION

Creates reproducible fingerprints of the given directory, along with commands
necessary (relative to measured path, or if supplied - the optional reported
path) to reproduce the measurement using only standard core GNU userland.

The output includes:

- hostname and datetime of **snazzer-measure** invocation
- `du -bs` (bytes used)
- `sha512sum` of the result of a reproducible tarball of the directory
- `gpg2 --armor --sign` of the same
- instructions for reproducing or verifying each of the above
- `tar --version`, `tar --show-defaults`

# OPTIONS

- **--help**: Brief help message
- **--version**: Print version
- **--man**: Full documentation
- **--man-roff**: Full documentation as \*roff output, Eg:

        snazzer-measure --man-roff | nroff -man

- **--man-markdown**: Full documentation as markdown output, Eg:

        snazzer-measure --man-markdown > snazzer-measure-manpage.md

# ENVIRONMENT

- snazzer\_sig\_func

    Function generating PGP SIGNATURE text. Takes input from stdin, output to
    stdout. Signatures can be disabled with [SNAZZER\_SIG\_ENABLE](https://metacpan.org/pod/SNAZZER_SIG_ENABLE). Default:

        snazzer_sig_func() {
            gpg2 --quiet --no-greeting --batch --use-agent --armor --detach-sign -
        }

- SNAZZER\_SIG\_ENABLE

    If set to 0, GPG signing is disabled and snazzer\_sig\_func() is not called.

- SNAZZER\_MEASUREMENTS\_EXCLUDE\_FILE

    A filename within the measured directory of a newline-separated list of shell
    glob patterns to exclude from measurements. Default:

        SNAZZER_MEASUREMENTS_EXCLUDE_FILE=".snapshot_measurements.exclude"

- MY\_KEYFILES\_ARE\_INVINCIBLE=1

    Skip sanity check/abort when gpg secret key exists on a subvolume included in
    default snazzer snapshots

- SNAZZER\_USE\_UTC

    Use UTC times of the form `YYYY-MM-DDTHHMMSSZ` instead of the default local
    time+offset `YYYY-MM-DDTHHMMSS+hhmm`

- SNAZZER\_SUBVOLS\_EXCLUDE\_FILE

    Filename of newline separated list of shell glob patterns of subvolume pathnames
    which should be excluded from `snazzer --all` invocations; compatible with
    `--exclude-from` for **du** and **tar**.  Examples of subvolume patterns to
    exclude from regular snapshotting: \*secret\*, /var/cache, /var/lib/docker/\*,
    .snapshots.  **NOTE:** `.snapshotz` is always excluded.
    Default:

        SNAZZER_SUBVOLS_EXCLUDE_FILE="/etc/snazzer/exclude.patterns"

## sudo requirements

When running **snazzer-measure** as a non-root user, certain commands will be
prefixed with `sudo`. The following lines in `/etc/sudoers` or
`/etc/sudoers.d/snazzer` should suffice for scripted jobs such as cron (replace
`measureuser` with the actual user name you are setting up for this task):

    measureuser ALL=(root:nobody) NOPASSWD:NOEXEC: \
        /bin/cat */.snapshotz/*/.snapshot_measurements.exclude, \
        /usr/bin/du -bs --one-file-system --exclude-from * */.snapshotz/*, \
        /usr/bin/find */.snapshotz/* \
            -xdev -not -path /*/.snapshotz/* -printf %P\\\\0, \
        /bin/tar --no-recursion --one-file-system --preserve-permissions \
            --numeric-owner --null --create --to-stdout \
            --directory */.snapshotz/* --files-from * \
            --exclude-from */.snapshotz/*/.snapshot_measurements.exclude

# EXIT STATUS

**snazzer-measure** will abort with an error message printed to STDERR and
non-zero exit status under the following conditions:

- 1. Invalid argument
- 2. Path string not specified
- 4. GPG signature would have been generated with a secret keyfile stored
in a subvolume which has not been excluded from default snazzer snapshots, see
[IMPORTANT](https://metacpan.org/pod/IMPORTANT) below
- 5. Expected the .snazzer\_measurements.exclude file to contain an entry
for the .snazzer\_measurements file

# IMPORTANT

Please note that if you are using this tool to gain some form of integrity
measurement (Eg. you want to detect tampering), GPG private keys used for the
signing operation mustn't be exposed among the directories being measured.

Put another way: it makes no sense to GPG-sign measurements of a directory if
those very same directories contain the GPG private key material required to
re-sign modifications made by anyone who happens to be looking.

# BUGS AND LIMITATIONS

- MY\_KEYFILES\_ARE\_INVINCIBLE

    The sanity check for location of GPG secret keyfile may be more annoying than
    helpful on installations using smartcards, TPMs, or other methods of protecting
    keyfiles - hence the **MY\_KEYFILES\_ARE\_INVINCIBLE** work-around.

- Temporary files

    To avoid unnecessary I/O, gpg signing and shasumming are done in parallel from
    the same `tar --to-stdout` pipe; this involves creating a temporary named pipe
    which is normally removed at the end of a successful run, but will be left
    behind should a failure occur. These are randomly named with `mktemp` and mode
    0700, inside a `mktemp -d` directory also with 0700 permissions.

# SEE ALSO

snazzer, snazzer-prune-candidates, snazzer-receive

# AUTHOR

Snazzer Authors are listed in the AUTHORS.md file in the root of this
distribution. See https://github.com/csirac2/snazzer for more information.
NOTE: Please extend that file, not this notice.

# LICENSE AND COPYRIGHT

Copyright (C) 2015-2016, Snazzer Authors All rights reserved.

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
