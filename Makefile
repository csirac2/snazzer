all: markdown manpages AUTHORS.md

INSTALL_PREFIX:=/usr/local

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
	rm -f bats
	rm -rf tmp/bats
	[ ! -d tmp ] || rmdir tmp

test: bats-tests prune-tests

ls_bin = $(shell find . -maxdepth 1 -executable -type f -printf '%P\n')

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
	PATH=.:$$PATH bats tests/

bats:
	@PATH=.:$$PATH bats --help >/dev/null || (                  \
		mkdir tmp;                                              \
		git clone https://github.com/sstephenson/bats tmp/bats; \
		ln -s tmp/bats/bin/bats .;                              \
	)

prune-tests:
	./snazzer-prune-candidates --tests

markdown: $(addprefix doc/, $(addsuffix .md, $(call ls_bin)))

doc/%.md: % | doc
	./$< --man-markdown >$@

doc:
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
.PHONY: all clean distclean test bats-tests bats prune-tests
.PHONY: rewrite-shebangs-to-bin rewrite-shebangs-to-env
