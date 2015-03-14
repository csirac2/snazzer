# NAME

snazzer-prune-candidates - reduce a set of lines containing datetimes to only
those which are no longer needed to meet retention preferences

# SYNOPSIS

    find /some/.snapshotz -maxdepth 1 -mindepth 1 -type d | \
      snazzer-prune-candidates | xargs btrfs subvolume delete

    echo -e "2015-02-01T000000Z\n2015-02-01T000010Z" | snazzer-prune-candidates

    snazzer-prune-candidates --gen-example-input  | \
      ./snazzer-prune-candidates --invert

# OPTIONS

- **--yearlies**=N or **SNAZZER\_YEARLIES\_TO\_KEEP**=N

    Keep one date per year for the last N years. Default: 1000

- **--monthlies**=N or **SNAZZER\_MONTHLIES\_TO\_KEEP**=N

    Keep one date per month for the last N months. Default: 12

- **--daylies**=N or **SNAZZER\_DAYLIES\_TO\_KEEP**=N

    Keep one date per day for the last N days. Default: 32

- **--hourlies**=N or **SNAZZER\_HOURLIES\_TO\_KEEP**=N

    Keep one date per hour for the last N hours. Default: 24

- **--invert**

    Invert output to contain only those lines which should be retained

- **--gen-example-input**

    Generate example datetime strings suitable for testing

- **--verbose**

    Verbose debugging output to STDERR

- **--help**

    Brief help message

- **--man**

    Full documentation

- **--man-roff**: Full documentation as \*roff output, Eg:

        snazzer-prune-candidates --man-roff | nroff -man

- **--man-markdown**: Full documentation as markdown output, Eg:

        snazzer-prune-candidates --man-markdown > snazzer-prune-candidates-man.md

- **--tests**

    Run tests (for developers/maintainers)

# DESCRIPTION

**snazzer-prune-candidates** reads lines of input from STDIN which are expected
to end in datetimes which are a subset of valid ISO 8601 strings:

    YYYY-MM-DD
    YYYY-MM-DDTHHMMSSZ
    YYYY-MM-DDTHHMMSS+HH
    YYYY-MM-DDTHHMMSS-HHMM

The parsing is a dumb regex to avoid library dependencies. It is lax about what,
if anything separates date or time parts - so for example, the following are
also valid (and demonstrate that only the end of these lines are parsed - but
note that if a line is considered unnecessary, it will be printed unchanged in
full to STDOUT):

    /any/old/junk/YYYYMMDD
    /any/old/junk/YYYY_MM_DDTHH:MM:SSZ
    /any/old/junk/YYYY-MM-DDTHH_MM_SS+HH:MM

Lines which aren't required to meet retention preferences are printed to STDOUT.

**NOTE:** Command-line options override environment variables.

**NOTE:** the description in [OPTIONS](https://metacpan.org/pod/OPTIONS) mentions "last N <years/months/etc>".
This refers to the period of time looking back from the most recent date seen at
the input. **snazzer-prune-candidates** does not use the local system time for
any decision-making part of the program.

# EXIT STATUS

**snazzer-prune-candidates** will abort with an error message printed to STDOUT
and non-zero exit status under the following conditions:

- 1 - A retention preference value contains anything other than digits
- 2 - Line does not end in a valid datetime string pattern
- 3 - Datetime contains obviously non-sensical digits

# BUGS AND LIMITATIONS

- Homebrew datetime code warning

    Due to a desire to avoid any non-core library dependencies there may be bugs
    with all the fun things that happen with home-brew time handling code: daylight
    savings, leap-years/hours/minutes/seconds and treatment of mixed timezones.

    A future version should try to use an appropriate datetime library to completely
    offload normalization, differencing and comparison of datetimes when available.

- When some datetimes are very close together: why they mightn't be pruned

    **snazzer-prune-candidates** iterates over each line of the input several times:
    once each to mark datetimes required to be kept to meet hourly, daily, monthly
    and yearly retention preferences. At the end of this process, all unmarked lines
    may safely be dropped and those are emitted for pruning.

    However, rather than require exactly 60mins, 24hrs, 28/29/30/31 days etc.
    between snapshots - which would risk dropping some previously retained datetimes
    depending on how far your snapshot runs drift from their usual schedule - the
    algorithm instead marks whichever datetime would most closely satisfy the
    retention requirement relative to the previously marked item.

    The end result is that occasionally (for example) a snapshot which has been
    marked as the best choice to meet the monthly requirement isn't quite the same
    snapshot as the one that has already been marked to meet the daily retention
    requirement, although they may be very close together in time. In fact, when
    starting out from very few snapshots to begin with, you may find several
    snapshots very close together are being retained toward the end of your set of
    snapshots due to the coarser retention periods marking out snapshots which are
    only a few minutes/hours older than other marked snapshots simply because they
    are slightly closer to the next retention interval (even if that difference
    seems trivial). If this bothers you, please provide feedback or patches to the
    author.

# SEE ALSO

snazzer, snazzer-measure, snazzer-receive

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
