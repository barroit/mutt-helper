# SPDX-License-Identifier: GPL-3.0-or-later

prefix ?= $(HOME)/.local/bin

.PHONY: install

install:

$(prefix):
	mkdir $(prefix)

install: $(prefix)
	set -e && \
	find . -name *.sh -exec realpath {} \; | while read target; do \
		ln -sf $$target $(prefix)/; \
		printf '%s -> %s\n' $(prefix)/$$(basename $$target) $$target; \
	done
