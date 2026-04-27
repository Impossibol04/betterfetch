PREFIX ?= /usr/local
DESTDIR ?=
SCRIPT := betterfetch.sh
BINDIR := $(DESTDIR)$(PREFIX)/bin
TARGET := $(BINDIR)/betterfetch

.PHONY: install uninstall check test

install:
	install -d "$(BINDIR)"
	install -m 755 "$(SCRIPT)" "$(TARGET)"

uninstall:
	rm -f "$(TARGET)"

check: test

test:
	bash tests/run.sh
