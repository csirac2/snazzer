# NAME

snazzer-measure - report shasums & PGP signatures of content under a given path,
along with commands to reproduce or verify data is unchanged

# SYNOPSIS

    snazzer-measure /some/path >> .snapshot_measurements

# DESCRIPTION

Creates reproducable fingerprints of the content under a given directory, along
with the commands necessary to reproduce the measurement using only standard
core GNU userland utilities.

The output includes:

- - `du -bs --time` (bytes used, most recently modified file datetime)
- - sha512sum of the result of a reproducible tarball of the directory
- - `gpg2 --armor --sign` of the same
- - instructions for reproducing or verifying each of the above
- - hostname and datetime of **snazzer-measure** invocation
- - `tar --version`, `tar --show-defaults`

# OPTIONS

- - **SNAZZER\_SIG\_CMD** (envar): Command to generate PGP SIGNATURE text.
Takes input from stdin, output to stdout. Signatures can be disabled with
`SNAZZER_SIG_CMD=' '`. Default:

        DEFAULT_SIG_CMD="gpg2 --quiet --no-greeting --batch --use-agent --armor \
            --detach-sign -"

- - **SNAZZER\_MEASUREMENTS\_FILE** (envar): A filename within the measured
directory excluded from measurements (changes to this file do not affect
results). Default:

        SNAZZER_MEASUREMENTS_FILE=".snapshot_measurements"

- - **MY\_KEYFILES\_ARE\_INVINCIBLE**=1 (envar): skip sanity check/abort when
gpg secret key exists on a subvolume included in default snazzer snapshots
- - **SNAZZER\_USE\_UTC** (envar): use UTC times of the form
`YYYY-MM-DDTHHMMSSZ` instead of the default local time+offset
`YYYY-MM-DDTHHMMSS+hhmm`
- **--help**

    Brief help message

- **--man**

    Full documentation

- **--man-roff**: Full documentation as \*roff output, Eg:

        snazzer-measure --man-roff | nroff -man

- **--man-markdown**: Full documentation as markdown output, Eg:

        snazzer-measure --man-markdown > snazzer-manpage.md

# EXIT STATUS

**snazzer-measure** will abort with an error message printed to STDERR and
non-zero exit status under the following conditions:

- 1 - Invalid argument
- 2 - Path string not specified
- 3 - Path string not a directory
- 4 - GPG signature would have been generated with a secret keyfile stored
in a subvolume which has not been excluded from default snazzer snapshots, see
[\*\*\*IMPORTANT\*\*\*](https://metacpan.org/pod/***IMPORTANT***) below
- 5 - Expected the .snazzer\_measurements.exclude file to contain an entry
for the .snazzer\_measurements file

# \*\*\*IMPORTANT\*\*\*

Please note that if you are using this tool to gain some form of integrity
measurement (Eg. you want to detect tampering), GPG private keys used for the
signing operation mustn't be exposed among the directories being measured.

Put another way: it makes no sense to GPG-sign measurements of a directory if
those very same directories contain the GPG private key material required to
re-sign modifications made by anyone who happens to be looking.

# BUGS AND LIMITATIONS

- **MY\_KEYFILES\_ARE\_INVINCIBLE**

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
