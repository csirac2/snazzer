# Change Log #
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] ##
### Added ###
- For the initial creation of the `.snapshotz` folder, Snazzer now copies owner and group from the source subvolume.
  The default permissions stay 0700, so the owner of the source subvolume now can read and delete snapshots by default,
  while group and others still have no permission for anything. For example, this means that if you use home directory
  subvolumes, a user can now read and delete their home directory snapshots without root permissions. This only happens
  for new subvolumes, but you can always change `.snapshotz` ownership (and permissions) by hand as well.
### Changed ###
### Deprecated ###
### Removed ###
### Fixed ###

## [0.0.3] - 2017-06-13 ##
### Changed ###
- Snazzer doesn't treat all patterns in `/` like they were implicitly pre- and suffixed with `*`.
  This behaviour now has to be specified explicitly.
- Snazzer now explicitly makes subvolumes absolute by prefixing with `/`.
  - All entries in `/etc/snazzer/exclude.patterns` need to be either absolute
    (start with `/`) or start with a `*`.
  - Paths displayed by snazzer are now absolute as well.
### Fixed ###
- snazzer-receive compatibility issue with btrfs-progs 4.11 onwards

## [0.0.2] - 2016-12-28 ##
First official snazzer release.
### Changed ###
- Renamed doc/ -> docs/ for future github-pages work

### Added ###
- --version switch implemented on all scripts

## 0.0.1 - 2016-12-28 ##
Unofficial pre-release of the current state of snazzer, as there will be
breaking changes between the current state and official releases in the near future.



This uses [Keep a CHANGELOG](http://keepachangelog.com/) as a template.

[Unreleased]: https://github.com/csirac2/snazzer/compare/v0.0.3...HEAD
[0.0.2]: https://github.com/csirac2/snazzer/compare/v0.0.1...v0.0.2
[0.0.3]: https://github.com/csirac2/snazzer/compare/v0.0.2...v0.0.3
