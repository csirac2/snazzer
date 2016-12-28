# Change Log #
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## 0.1.0 - 2017-XY-XY? ##
First official snazzer release.

### Added ###
### Changed ###
- Snazzer doesn't treat all patterns in `/` like they were implicitly pre- and suffixed with `*`.
  This behaviour now has to be specified explicitly.
- Snazzer now explicitly makes subvolumes absolute by prefixing with `/`.
  - All entries in `/etc/snazzer/exclude.patterns` need to be either absolute
    (start with `/`) or start with a `*`.
  - Paths displayed by snazzer are now absolute as well.
### Deprecated ###
### Removed ###
### Fixed ###

## 0.0.2 - 2016-12-28 ##
### Changed ###
- Renamed doc/ -> docs/ for future github-pages work

### Added ###
- --version switch implemented on all scripts

## 0.0.1 - 2016-12-28 ##
Unofficial pre-release of the current state of snazzer, as there will be
breaking changes between the current state and the first official release.



This uses [Keep a CHANGELOG](http://keepachangelog.com/) as a template.

[Unreleased]: https://github.com/csirac2/snazzer/compare/v0.0.2...HEAD
[0.0.2]: https://github.com/csirac2/snazzer/compare/v0.0.1...v0.0.2
