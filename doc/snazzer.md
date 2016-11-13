# NAME

snazzer - create read-only `/subvol/.snapshotz/[isodate]` btrfs snapshots,
offers snapshot pruning and measurement

# SYNOPSIS

    snazzer [--prune|--measure [--force ]] [--dry-run] --all

    snazzer [--prune|--measure [--force ]] [--dry-run] --all [mountpoint]

    snazzer [--prune|--measure [--force ]] [--dry-run] subvol1 [subvol2 [...]]

# DESCRIPTION

Examples:

Snapshot all non-excluded subvols on all mounted btrfs filesystems:

    snazzer --all

Prune all non-excluded subvols on all mounted btrfs filesystems:

    snazzer --prune --force --all

Append output of **snazzer-measure** to
`/path/to/subvol/.snapshotz/.measurements/[isodate]` for all snapshots of all
subvolumes on all mounted btrfs filesytems (slow!):

    snazzer --measure --force --all

As above, skipping snapshots already measured by this host (recommended):

    snazzer --measure --all

Print rather than execute commands for snapshotting all non-excluded subvols for
the filesystem mounted at /mnt (including /mnt itself):

    snazzer --dry-run --all /mnt

Prune only the explicitly named subvols at /srv, /var/log and root:

    snazzer --prune /srv /var/log /

# OPTIONS

- **--all** **\[mountpoint\]**: act on all subvolumes under mountpoint. If
mountpoint is omitted, **snazzer** acts on all mounted btrfs filesystems.
- **--prune**: delete rather than create snapshots. Exactly which are no
longer needed is **snazzer-prune-candidates**'s role, documented separately
- **--measure**: append output of **snazzer-measure** to
`/path/to/subvol/.snapshotz/.measurements/[isodate]` By default, only snapshots
which haven't been measured by this hostname are updated - use **--force** to
measure all snapshots
- **--force**: required for **--prune** to carry out any pruning operation.
For **--measure**, this switch overrides the default behaviour of skipping
snapshots already measured by current hostname
- **--list-subvolumes**: list subvolumes that would be acted on
- **--list-snapshots**: list snapshots under subvolumes as above
- **--dry-run**: print rather than execute commands that would be run
- **--help**: Brief help message
- **--man**: Full documentation
- **--man-roff**: Full documentation as \*roff output, Eg:

        snazzer --man-roff | nroff -man

- **--man-markdown**: Full documentation as markdown output, Eg:

        snazzer --man-markdown > snazzer-manpage.md

# ENVIRONMENT

- SNAZZER\_SUBVOLS\_EXCLUDE\_FILE

    Filename of newline separated list of shell glob patterns of subvolume pathnames
    which should be excluded from `snazzer --all` invocations; compatible with
    `--exclude-from` for **du** and **tar**.  Examples of subvolume patterns to
    exclude from regular snapshotting: \*secret\*, var/cache, var/lib/docker/\*,
    .snapshots. The patterns are matched against subvolumes as listed by
    `btrfs subvolume list <path`>, without a leading /.
    Note that   **NOTE:** `.snapshotz` is always excluded.
    Default:

        SNAZZER_SUBVOLS_EXCLUDE_FILE="/etc/snazzer/exclude.patterns"

- SNAZZER\_USE\_UTC=1

    For snapshot naming and **snazzer-measure** output use UTC times of the form
    `YYYY-MM-DDTHHMMSSZ` instead of local time+offset `YYYY-MM-DDTHHMMSS+hhmm`

# BUGS AND LIMITATIONS

- Snapshot naming

    A choice has been made to mint a single datetime string which is used for all
    snapshot names in a given **snazzer** snapshot invocation, regardless of how long
    or at which exact time the snapshotting process takes place for each subvolume.
    This makes for consistency across all subvolumes and filesystems, so that
    identifying which snapshots were part of a given snapshotting run is possible.
    If the actual datetime of the snapshot event is important to you, this is
    available from the `btrfs subvolume show` command.

- SNAZZER\_SUBVOLS\_EXCLUDE\_FILE is used with grep -f

    A minimal (possibly buggy/incomplete) attempt is made to convert the shell glob
    patterns in this file to a regex suitable for grep -f. The assumption is that
    the exclude patterns file should only contain "boring" paths. Obvious regex
    characters are escaped, however there are likely hostile path glob patterns
    which will break things.

- .snapshot\_measurements.exclude is a work-around to the btrfs atime bug

    Snapshots may include empty directories under which some other subvol may have
    existed in the original, snapshotted subvolume. However, btrfs has a bug where
    these empty directories behave differently to empty directories created with
    `mkdir`: atimes always return with the current local time, which is obvioulsy
    different from one second to the next. So we have no hope of creating
    reproducible shasums or PGP signatures unless those directories are excluded
    from our measurements of the snapshot. See also: 
    [https://bugzilla.kernel.org/show\_bug.cgi?id=95201](https://bugzilla.kernel.org/show_bug.cgi?id=95201)

# EXIT STATUS

**snazzer** will abort with an error message printed to STDERR and non-zero exit
status under the following conditions:

- 1. invalid arguments
- 2. path is not a filesystem mountpoint
- 3. one or more paths were not btrfs subvolumes
- 4. prune expected /path/to/subvol/.snapshotz directory which was missing
- 5. prune expected --dry-run or --force
- 6. tried to write a .snapshot\_measurements.exclude file in the snapshot
root, but it already exists in the current subvolume
- 7. tried to perform snapshot measurements while existing measurements are
already in progress, check lock dir at /var/run/snazzer-measure.lock
- 9. tried to display man page with a formatter which is not installed
- 10. missing `snazzer-measure` or `snazzer-prune-candidates` from PATH
- 11. missing `btrfs` command from PATH

# SEE ALSO

snazzer-measure, snazzer-prune-candidates, snazzer-receive

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
