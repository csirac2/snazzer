all: markdown manpages

release: all AUTHORS.md CHANGELOG.md

INSTALL_PREFIX:=/usr/local
ls_bin        :=$(shell find . -maxdepth 1 -executable -type f -printf '%P\n')
ls_bin_sh     :=$(shell find . -maxdepth 1 -executable -type f \
				 -exec sed -n '1s:^\#!.*[ /]sh$$:{}:p' {} \;)

install: install-bin install-man

clean:
	rm -f AUTHORS.md
	rm -f $(addprefix man/, $(addsuffix .8.gz, $(call ls_bin)))
	[ ! -d man ] || rmdir man
	for btrfs_mnt in btrfs.working.mnt btrfs-snapshots.working.mnt; do \
		! mountpoint -q "/tmp/snazzer-tests/$$btrfs_mnt" ||            \
		umount "/tmp/snazzer-tests/$$btrfs_mnt";                       \
	done
	rm -rf /tmp/snazzer-tests

distclean: clean
	rm -f tmp/bin/bats
	rm -rf tmp/bats
	[ ! -d tmp/bin ] || rmdir tmp/bin
	[ ! -d tmp ] || rmdir tmp

test: bats-tests prune-tests

uninstall:
	rm -f $(addprefix $(INSTALL_PREFIX)/bin/, $(call ls_bin))
	rm -f $(addprefix $(INSTALL_PREFIX)/share/man/man8/, $(addsuffix .8.gz, \
		$(call ls_bin)))

install-bin: $(addprefix $(INSTALL_PREFIX)/bin/, $(call ls_bin))

$(INSTALL_PREFIX)/bin/%: %
	install -Dm755 $< $@

install-man: $(addprefix $(INSTALL_PREFIX)/share/man/man8/, $(addsuffix .8.gz, \
	$(call ls_bin)))

$(INSTALL_PREFIX)/share/man/man8/%.8.gz: man/%.8.gz
	install -Dm644 $< $@

bats-tests: | bats
	PATH=.:tmp/bin:$$PATH bats tests/

bats:
	@PATH=tmp/bin:$$PATH bats --help >/dev/null || (\
		mkdir -p tmp/bin;\
		[ -f tmp/bats/bin/bats ] ||\
			git clone https://github.com/sstephenson/bats tmp/bats;\
		ln -s ../bats/bin/bats tmp/bin/;\
	)

prune-tests:
	./snazzer-prune-candidates --tests

shellcheck-tests: | shellcheck
	PATH=~/.cabal/bin:tmp/bin:$$PATH shellcheck $(call ls_bin_sh)

shellcheck:
	@PATH=~/.cabal/bin/:$$PATH shellcheck --version >/dev/null || (\
		mkdir -p tmp/bin;\
		if ! cabal --version >/dev/null; then\
			echo "ERROR: Missing cabal. Please install cabal-install" >&2;\
			exit 1;\
		fi;\
		cabal update;\
		cabal install ShellCheck;\
	)

markdown: $(addprefix docs/, $(addsuffix .md, $(call ls_bin)))

docs/%.md: % | docs
	./$< --man-markdown >$@

docs:
	mkdir $@

manpages: $(addprefix man/, $(addsuffix .8.gz, $(call ls_bin)))

man/%.8.gz: % | man
	./$< --man-roff | gzip >$@

man:
	mkdir $@

AUTHORS.md:
	echo "SNAZZER AUTHORS" > $@
	echo "===============" >>$@
	echo >>$@
	echo "Compiled automatically from git history, in alphabetical order:" >> $@
	echo >>$@
	git log --format='- %aN <%aE>'  | \
		sort -u |grep -v 'Paul.W Harvey <csirac2@gmail.com>' >> $@

# Print "0.0.1" from "v0.0.1-2-g4cb93f4", see also: tests/fixtures.sh
define git-describe-snazzer-version
$(shell git describe --tags | sed -n 's/v\?\([0-9.]*\).*/\1/p')
endef

define snazzer-version-escaped
$(subst .,\.,$(call git-describe-snazzer-version))
endef

# Sanity-check the changelog
CHANGELOG.md:
	@echo "Building snazzer version $(call git-describe-snazzer-version)"
	@printf "Checking there's a $@ entry for this version:\n    "
	@grep '^## $(call snazzer-version-escaped) - ' $@
	@printf "Checking the [Unreleased] URL:\n    "
	@grep '^\[Unreleased\]: https://github.com/csirac2/snazzer/compare/v$(call \
		snazzer-version-escaped)...HEAD' $@

.PHONY: CHANGELOG.md

# assumes "#!/usr/bin/env foo", rewrites to "#!/path/to/foo"
rewrite-shebangs-to-bin:
	for script in $(call ls_bin);\
		do\
		script_bin=$$(sed -n '1s:.*[ /][ /]*\([^ /]*\)$$:\1:p' "$$script");\
		sed -i "1s:.*[ /][ /]*\([^ /]*\)$$:#\!$$(which $$script_bin):g"\
			"$$script";\
	done

# assumes "#!/path/to/foo", rewrites to "#!/usr/bin/env foo"
rewrite-shebangs-to-env:
	for script in $(call ls_bin);\
		do\
		script_bin=$$(sed -n '1s:.*[ /][ /]*\([^ /]*\)$$:\1:p' "$$script");\
		sed -i "1s:.*[ /][ /]*\([^ /]*\)$$:#\!/usr/bin/env $$script_bin:g"\
			"$$script";\
	done

.PHONY: install uninstall install-bin install-man markdown manpages
.PHONY: all release clean distclean test bats-tests bats prune-tests
.PHONY: rewrite-shebangs-to-bin rewrite-shebangs-to-env
