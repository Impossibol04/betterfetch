PREFIX ?= /usr/local
DESTDIR ?=
SCRIPT := betterfetch.sh
BINDIR := $(DESTDIR)$(PREFIX)/bin
TARGET := $(BINDIR)/betterfetch

.PHONY: install install-user uninstall check

install:
	install -d "$(BINDIR)"
	install -m 755 "$(SCRIPT)" "$(TARGET)"

# Installation sans droits root (~/bin du standard XDG utilisateur)
install-user:
	$(MAKE) PREFIX="$(HOME)/.local" install

uninstall:
	rm -f "$(TARGET)"

check:
	bash -n "$(SCRIPT)"
	bash -n install.sh
