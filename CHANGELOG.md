# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-27

### Added

- Project packaging: `Makefile` (install/uninstall/check), `README.md`, `config.conf.example`.
- `BETTERFETCH_VERSION`, `--version` / `-V`, early-exit help `--help` / `-h` without writing config.
- `make check` : vérification syntaxe (`bash -n` sur `betterfetch.sh` et `install.sh`).
- [`install.sh`](install.sh) : installation universelle (`curl` ou `wget`, `--prefix`, `--system`, `--branch`, `--dry-run`).
- Cible `make install-user` ; README avec tableau distro / procédures multi-OS.

### Changed

- Documentation and repository hygiene (`.gitignore`, `.shellcheckrc`).
- README (sommaire, flux, désinstallation), licence MIT (`LICENSE`), URL du dépôt dans `BETTERFETCH_HOMEPAGE`.

### Links

- Upstream repository: https://github.com/Impossibol04/betterfetch
