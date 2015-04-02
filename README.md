snazzer
=======

btrfs snapshotting and backup system offering snapshot measurement, transport
and pruning.

Getting started
---------------

Examine the documentation, which includes usage information (requires pod2usage,
a part of perl core):

    snazzer --man
    snazzer-measure --man
    snazzer-receive --man
    snazzer-prune-candidates --man
    
Also viewable online at:
* https://github.com/csirac2/snazzer/blob/master/doc/snazzer.md
* https://github.com/csirac2/snazzer/blob/master/doc/snazzer-measure.md
* https://github.com/csirac2/snazzer/blob/master/doc/snazzer-receive.md
* https://github.com/csirac2/snazzer/blob/master/doc/snazzer-prune-candidates.md

Generate a test btrfs image and mount it:

    snazzer --generate-test-img test.img
    mount test.img /mnt
    snazzer --all /mnt # snapshot all subvols under /mnt
    snazzer --all /mnt # moar snapshots...
    snazzer --all /mnt # moar snapshots...
    # have unneeded snapshots now, prune them:
    snazzer --prune --force --all /mnt
    
generate measurement reports for each snapshot under
`/path/to/subvol/.snapshotz/.measurements/[isodate]`. Perhaps schedule
measurements to run after they've been received on your backup server
rather than burning up CPU and disk I/O on the original host:

    snazzer --measure --all /mnt

Now observe that running measure again, we're smart enough to skip
re-measuring snapshots which have already been measured by this host
(use --force to override this behaviour):

    snazzer --measure --all /mnt

View the snapshot measurement report for one of the snapshots (example only):

    cat /mnt/.snapshotz/.measurements/2015-03-25T100223+1100

Run one of the commands in the report to see if we can reproduce shasum  (example only):

    cd /mnt/.snapshotz/.measurements
    OLD=$(pwd); cd '../2015-03-25T100223+1100' && find . -xdev -print0 | LC_ALL=C sort -z | tar --null -T - --no-recursion --preserve-permissions --one-file-system -c --to-stdout --exclude-from '.snapshot_measurements.exclude' | sha512sum -b; cd "$OLD"

Run the gpg signature verification command listed in the report  (example only):

    cd /mnt/.snapshotz/.measurements
    OLD=$(pwd); SIG=$(mktemp) && cat 2015-03-25T100223+1100 | grep -v '/,/' | \
    sed -n '/> on schwing at 2015-03-25T100233+0000, gpg:/,/-----END PGP SIGNATURE-----/ { /-----BEGIN PGP SIGNATURE-----/{x;d}; H }; ${x;p}' \
    > $SIG && cd '../2015-03-25T100223+1100' && find . -xdev -print0 | \
    LC_ALL=C sort -z | tar --null -T - --no-recursion --preserve-permissions \
    --one-file-system -c --to-stdout --exclude-from \
    '.snapshot_measurements.exclude' | gpg2 --verify $SIG -; cd "$OLD"

Some observations:
* Yes, the verification commands are huge and ugly, but eminently reproducible.
* The effort we go to maintaining a list subvolumes in the
  `.snapshot_measurments.exclude` file automatically placed in each snapshot root
  is due to a btrfs bug which seems to awalys give a different bogus atime on
  any empty directory within a snapshot that happened to be a btrfs subvolume.
  Plain old empty directories created with mkdir have static/stable atimes.
  This bug prevents us from ever getting a repeatable sha512sum or PGP signature
  unless we exclude those directories from measurements in the snapshot. See
  https://bugzilla.kernel.org/buglist.cgi?quicksearch=btrfs%20atime&list_id=527771

Inspiration
-----------
Most mature backup solutions do not leverage btrfs features, particularly
copy-on-write snapshots or send/receive transport. This makes it too easy to end
up with VMs needlessly struggling with disk I/O throughput for hours per day
when a btrfs snapshot and send/receive operation would take minutes or even
seconds.

SuSE's `snapper` project was interesting enough to provide inspiration for the
naming of `snazzer`, but seems focused on supporting recovery from sysadmin
tasks and thus complements rather than provides a coherent basis for a
distributed backup solution. Additionally, whilst SuSE's `snapper` has few
dependencies we thought it would be possible to provide something using exactly
zero dependencies beyond only very basic core utilities present on even minimal
installation of any given distro.

Immediate goals and assumptions
-------------------------------
* Leverage btrfs (and eventually zfs) snapshots, send/receive features as the
  basis for part of an efficient and robust backup system.
* Clarification to the above: `snazzer` is aimed at supporting day-to-day
  operation of live running systems utilizing a backup "server" (from which
  remote ssh commands are made to receive new snapshots from each host), and is
  not necessarily a *complete* solution for everyone. Whilst snazzer-managed
  btrfs filesystems could be used for off-site backups with the help of full
  disk encryption such as LUKS or TrueCrypt, most enterprises should probably
  stick to more mature setups such as encrypted tarballs leveraging the
  organisation's existing key management systems and PKI.
* Provide easily reproducible sha512sum, GPG signatures etc. of snapshots to
  detect any btrfs shenanigans or malicious tampering.
* Zero config, or at least issue helpful _easily actionable_ error messages and
  sanity checks along the way.
* Zero dependencies, or as close as we can get. `snazzer-prune-candidates` uses
  perl, a core part of some distros but not others; python version coming soon.
* Simple architecture without databases, XML config or daemons.

Longer-term goals
-----------------
* Seamlessly support ZFS On Linux instead of or in addition to btrfs
* Implement `snazzer-prune-candidates` in a python version for those distros
  which have standardized on python rather than perl as part of base packages
* Distro packaging, starting with Debian
* Automated distro testing infrastructure
* Remove any lingering GNU-isms and keep POSIX sh code portable to BSDs for
  FreeBSD and OpenIndiana compatibility (assuming `snazzer` makes sense there)

License and Copyright
---------------------

Copyright (c) 2015, Paul Harvey <csirac2@gmail.com> All rights reserved.

This project uses the 2-clause Simplified BSD License.
