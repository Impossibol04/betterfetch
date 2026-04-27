# BetterFetch

Petit afficheur d’infos système en **Bash pur** (sans dépendance obligatoire hors outils Unix habituels) : logo ASCII, blocs étiquette / valeur, barres de remplissage mémoire, et bande de couleurs ANSI. Esprit proche de [fastfetch](https://github.com/fastfetch-cli/fastfetch) / neofetch, mais volontairement léger et modifiable dans un seul script.

**Dépôt officiel :** [github.com/Impossibol04/betterfetch](https://github.com/Impossibol04/betterfetch)

---

**EN (short):** Single-file Bash sysinfo with ASCII logo, labeled fields, optional Nerd Font–style glyphs, memory/swap bars, and an ANSI color strip.

---

## Sommaire

1. [Fonctionnement (vue d’ensemble)](#fonctionnement-vue-densemble)
2. [Prérequis](#prérequis)
3. [Installation](#installation)
4. [Utilisation](#utilisation)
5. [Configuration](#configuration)
6. [Développement et tests](#développement-et-tests)
7. [Publier ou mettre à jour le dépôt GitHub](#publier-ou-mettre-à-jour-le-dépôt-github)
8. [Licence](#licence)

---

## Fonctionnement (vue d’ensemble)

| Étape | Rôle |
|-------|------|
| Options `--help`, `--version` | Traitées tout au début : **aucune écriture** config/cache. |
| Config | Lecture de `config.conf` ; si absent, **création** d’un fichier par défaut. |
| Données | Lecture `/etc/os-release`, `/proc`, `df`, `free`, réseau, batterie, GPU (`lspci`), paquets (selon `PKG_MANAGERS`), etc. |
| Cache | Fichier dans `XDG_CACHE_HOME` pour CPU / GPU / paquets (TTL ~300 s). |
| Rendu | Logo + colonne d’infos alignées selon `LOGO_WIDTH`, puis palette selon `PALETTE_STYLE`. |

La logique métier et l’UI sont dans [`betterfetch.sh`](betterfetch.sh). Les modules affichés dépendent du niveau `--detail` (`balanced`, `full`, `ultra`, `dual_mode`) et de `--enable` / `--disable`, avec option d’ordre perso via `MODULE_ORDER` si `USE_CONFIG_MODULE_ORDER=1`.

---

## Prérequis

- **Bash** (associatif arrays : viser Bash **4.x** ou plus récent).
- Commandes usuelles : `awk`, `sed`, `grep`, `uname`, `df`, `free`, `ip`, etc.
- Pour les icônes « riches », une police **Nerd Font** dans le terminal ; sinon `--ascii` ou config `FORCE_ASCII=1`.

---

## Installation

### Cloner puis installer (recommandé)

```bash
git clone https://github.com/Impossibol04/betterfetch.git
cd betterfetch
make PREFIX="$HOME/.local" install   # binaire : ~/.local/bin/betterfetch
```

Assurez-vous que `~/.local/bin` est dans votre `PATH` (souvent déjà le cas sous Arch).

Installation système :

```bash
sudo make install    # PREFIX=/usr/local par défaut → /usr/local/bin/betterfetch
```

Désinstallation : `make uninstall` (même `PREFIX`).

### Sans cloner (fichier seul)

```bash
curl -fsSL -o betterfetch https://raw.githubusercontent.com/Impossibol04/betterfetch/main/betterfetch.sh
chmod +x betterfetch
sudo mv betterfetch /usr/local/bin/betterfetch   # ou ~/bin, etc.
```

*(La commande `curl` ne fonctionnera qu’après votre premier push du fichier sur la branche `main`.)*

---

## Utilisation

```bash
betterfetch
betterfetch --detail full --palette ansi16
betterfetch --help
betterfetch --version    # affiche aussi l’URL du dépôt si configurée dans le script
```

Intégration au démarrage du shell (exemple) :

```bash
# ~/.bashrc ou ~/.zshrc — uniquement dans un terminal interactif si vous préférez
[[ $- != *i* ]] && return
command -v betterfetch >/dev/null && betterfetch
```

---

## Configuration

| Emplacement | Rôle |
|-------------|------|
| `$XDG_CONFIG_HOME/betterfetch/config.conf` | Configuration persistante (souvent `~/.config/betterfetch/config.conf`). |
| `$XDG_CACHE_HOME/betterfetch_cache_$UID` | Cache (TTL 300 s par défaut). |

Au premier lancement, un fichier minimal est créé si absent.

Référence commentée : [`config.conf.example`](config.conf.example).

### Variables principales

| Variable | Description |
|----------|-------------|
| `THEME` | `default`, `dracula`, `solarized`, `nord`, `gruvbox` |
| `VISUAL_STYLE` | `minimal`, `modern`, `retro`, `hybrid` |
| `MODE` | `normal` ou `compact` |
| `DETAIL_LEVEL` | `balanced`, `full`, `ultra`, `dual_mode` |
| `PALETTE_STYLE` | `ansi8` (défaut), `ansi16`, `gradient`, … |
| `USE_CONFIG_MODULE_ORDER` | `1` pour utiliser `MODULE_ORDER` comme ordre final |
| `MODULE_ORDER` | Liste ordonnée des modules à afficher |
| `PKG_MANAGERS` | Ordre des gestionnaires testés pour le décompte de paquets |

Liste complète des options CLI : `betterfetch --help`.

---

## Développement et tests

```bash
make check          # bash -n, smoke test HOME isolé, shellcheck si installé
./tests/run.sh
```

Installer [ShellCheck](https://www.shellcheck.net/) pour des analyses statiques (`pacman -S shellcheck` sur Arch).

---

## Publier ou mettre à jour le dépôt GitHub

Le dépôt [Impossibol04/betterfetch](https://github.com/Impossibol04/betterfetch) peut être vide au début : poussez **ce dossier** (ou une copie dédiée) comme racine du repo.

```bash
cd /chemin/vers/betterfetch    # répertoire contenant betterfetch.sh, Makefile, README.md, …
git init
git add betterfetch.sh Makefile README.md CHANGELOG.md LICENSE config.conf.example \
        tests/run.sh .gitignore .shellcheckrc
git commit -m "Initial import: BetterFetch 1.0.0"
git branch -M main
git remote add origin https://github.com/Impossibol04/betterfetch.git
git push -u origin main
```

- **HTTPS** : GitHub demandera souvent un [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) à la place du mot de passe.
- **SSH** : `git remote set-url origin git@github.com:Impossibol04/betterfetch.git` après avoir ajouté une [clé SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) à votre compte.

Ensuite, à chaque modification : `git add …`, `git commit`, `git push`. Créez des [releases](https://github.com/Impossibol04/betterfetch/releases) pour figurer la version (alignée sur `BETTERFETCH_VERSION` dans `betterfetch.sh`) et notez les changements dans [`CHANGELOG.md`](CHANGELOG.md).

---

## Licence

Voir [LICENSE](LICENSE) (MIT).
