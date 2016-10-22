all: markdown manpages AUTHORS.md

INSTALL_PREFIX:=/usr/local/bin

$(INSTALL_PREFIX)/%: %
	install -Dm755 $< $@

install: $(shell find . -maxdepth 1 -executable -type f \
	-printf '$(INSTALL_PREFIX)/%p\n' )

uninstall:
	rm $(shell find . -maxdepth 1 -executable -type f \
	   	-printf '$(INSTALL_PREFIX)/%p\n')

clean:
	rm -f AUTHORS.md
	rm -rf /tmp/snazzer-tests

test: bats-tests prune-tests

bats-tests: | bats
	PATH=.:$$PATH bats tests/

bats:
	PATH=.:$$PATH bats --help >/dev/null || (                   \
		mkdir tmp;                                              \
		git clone https://github.com/sstephenson/bats tmp/bats; \
		ln -s tmp/bats/bin/bats .;                              \
	)

prune-tests:
	./snazzer-prune-candidates --tests

markdown: $(shell find . -maxdepth 1 -executable -type f -printf 'doc/%p.md\n')\
   	| doc

manpages: $(shell find . -maxdepth 1 -executable -type f -printf 'man/%p.8\n') \
	| man

man/%.8: %
	./$< --man-roff >$@

doc/%.md: %
	./$< --man-markdown >$@

doc:
	mkdir $@

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

.PHONY: uninstall clean test bats-tests bats prune-tests
