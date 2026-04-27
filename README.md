# BetterFetch

Affichage d’informations système dans le terminal : logo ASCII, champs étiquetés, barres (mémoire, etc.) et bande de couleurs ANSI. Un seul script Bash, dans l’esprit de [fastfetch](https://github.com/fastfetch-cli/fastfetch) / neofetch, en version plus légère.

**Dépôt :** [github.com/Impossibol04/betterfetch](https://github.com/Impossibol04/betterfetch)

## Sommaire

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Désinstallation](#désinstallation)
- [Utilisation](#utilisation)
- [Configuration](#configuration)
- [Développement](#développement)

## Prérequis

- **Bash 4+** (tableaux associatifs). Sur Alpine ou images minimalistes : paquet `bash` — `/bin/sh` ne suffit pas.
- **curl** ou **wget** si vous utilisez l’installation en ligne ([`install.sh`](install.sh)).
- Outils courants : `awk`, `sed`, `uname`, `df`, `free`, `ip`, etc. (selon l’OS, certaines infos peuvent manquer).
- Icônes « spéciales » : police type **Nerd Font** ; sinon `--ascii` ou `FORCE_ASCII=1` dans la config.

## Installation

BetterFetch s’installe comme **un exécutable** `betterfetch` placé dans un répertoire de votre **`PATH`** (pas de paquet `pacman` / `apt` fourni ici).

### Option A — `install.sh` (recommandé)

Par défaut : **`~/.local/bin/betterfetch`** (pas de `sudo`).

```bash
curl -fsSL https://raw.githubusercontent.com/Impossibol04/betterfetch/main/install.sh | bash
```

Sans `curl` :

```bash
wget -qO- https://raw.githubusercontent.com/Impossibol04/betterfetch/main/install.sh | bash
```

Depuis un **clone** du dépôt (sans retélécharger depuis le réseau) :

```bash
chmod +x install.sh
./install.sh
sudo ./install.sh --system    # /usr/local/bin (sudo si besoin)
```

Autres options utiles : `--prefix CHEMIN`, `--branch NOM` (branche ou tag), `--dry-run`.

Pensez à avoir **`~/.local/bin`** dans le `PATH` :

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Option B — `Makefile` (depuis un clone)

```bash
git clone https://github.com/Impossibol04/betterfetch.git
cd betterfetch

make install-user                 # ~/.local/bin/betterfetch
# ou
sudo make install                 # /usr/local/bin/betterfetch
```

### Option C — Copie manuelle du script

```bash
curl -fsSL -o betterfetch https://raw.githubusercontent.com/Impossibol04/betterfetch/main/betterfetch.sh
chmod +x betterfetch
mv betterfetch ~/.local/bin/     # ou un autre dossier déjà dans le PATH
```

*(Les URL `raw.githubusercontent.com` supposent que les fichiers existent sur la branche `main`.)*

## Désinstallation

### Trouver le binaire

```bash
command -v betterfetch
```

### Installé avec **Makefile**

Utiliser le **même `PREFIX` (et `DESTDIR` si utilisé)** qu’à l’installation :

| Installation | Désinstallation |
|----------------|-----------------|
| `sudo make install` | `sudo make uninstall` |
| `make install-user` | `make PREFIX="$HOME/.local" uninstall` |

### Installé avec **`install.sh`** ou **copie manuelle**

Supprimer le fichier concerné, par exemple :

```bash
rm -f "$HOME/.local/bin/betterfetch"
sudo rm -f /usr/local/bin/betterfetch
```

### Config et cache (facultatif)

Non supprimés automatiquement :

- config : `~/.config/betterfetch/` (ou `$XDG_CONFIG_HOME/betterfetch/`)
- cache : fichier `betterfetch_cache_$UID` sous `$XDG_CACHE_HOME` (souvent `~/.cache` ou `/tmp`)

```bash
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/betterfetch"
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/betterfetch_cache_$UID"
```

## Utilisation

```bash
betterfetch
betterfetch --detail full --palette ansi16
betterfetch --help
betterfetch --version
```

Lancer au démarrage du shell (exemple, à adapter) :

```bash
[[ $- != *i* ]] && return
command -v betterfetch >/dev/null 2>&1 && betterfetch
```

## Configuration

| Emplacement | Rôle |
|-------------|------|
| `$XDG_CONFIG_HOME/betterfetch/config.conf` | Réglages (souvent `~/.config/betterfetch/config.conf`) |
| `$XDG_CACHE_HOME/betterfetch_cache_$UID` | Cache (TTL ~300 s) |

Au premier lancement, un `config.conf` minimal est créé s’il manque. Modèle commenté : [`config.conf.example`](config.conf.example).

| Variable | Rôle principal |
|----------|------------------|
| `THEME` | `default`, `dracula`, `solarized`, `nord`, `gruvbox` |
| `VISUAL_STYLE` | `minimal`, `modern`, `retro`, `hybrid` |
| `MODE` | `normal` ou `compact` |
| `DETAIL_LEVEL` | `balanced`, `full`, `ultra`, `dual_mode` |
| `PALETTE_STYLE` | `ansi8`, `ansi16`, `gradient`, … |
| `USE_CONFIG_MODULE_ORDER` | `1` pour imposer l’ordre `MODULE_ORDER` |
| `MODULE_ORDER` | Ordre des modules |
| `PKG_MANAGERS` | Ordre des gestionnaires testés pour le nombre de paquets |

Toutes les options en ligne de commande : `betterfetch --help`.

## Développement

```bash
make check    # bash -n sur betterfetch.sh et install.sh
```

Optionnel : [ShellCheck](https://www.shellcheck.net/) — `shellcheck betterfetch.sh install.sh`.

---

Auteur : [@Impossibol04](https://github.com/Impossibol04)
