# BetterFetch

Petit afficheur d’infos système en **Bash pur** (sans dépendance obligatoire hors outils Unix habituels) : logo ASCII, blocs étiquette / valeur, barres de remplissage mémoire, et bande de couleurs ANSI. Esprit proche de [fastfetch](https://github.com/fastfetch-cli/fastfetch) / neofetch, mais volontairement léger et modifiable dans un seul script.

**Dépôt officiel :** [github.com/Impossibol04/betterfetch](https://github.com/Impossibol04/betterfetch)

---

**EN (short):** Single-file Bash sysinfo with ASCII logo, labeled fields, optional Nerd Font–style glyphs, memory/swap bars, and an ANSI color strip.

---

## Sommaire

- [Fonctionnement (vue d’ensemble)](#fonctionnement-vue-densemble)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Désinstallation](#désinstallation)
- [Utilisation](#utilisation)
- [Configuration](#configuration)
- [Développement](#développement)

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

- **Bash 4+** (tableaux associatifs). Sur **Alpine**, **busybox** ou systèmes minimalistes : installez le paquet `bash` — le `/bin/sh` par défaut ne suffit pas.
- **curl** ou **wget** (pour l’installation « en ligne » via [`install.sh`](install.sh)).
- Utilitaires usuels : `awk`, `sed`, `grep`, `uname`, `df`, `free`, `ip` ou équivalent… (le script adapte ce qu’il peut selon l’OS).
- Pour les icônes « riches », une police **Nerd Font** dans le terminal ; sinon `--ascii` ou `FORCE_ASCII=1`.

### Bash selon la famille de distro (à titre indicatif)

| Famille | Commande typique pour installer Bash |
|---------|--------------------------------------|
| Debian / Ubuntu | `sudo apt install bash` |
| Fedora / RHEL / derivatives | `sudo dnf install bash` |
| Arch / Manjaro | Bash est en général déjà présent (`pacman -S bash` si besoin) |
| openSUSE | `sudo zypper install bash` |
| Alpine | `sudo apk add bash` |
| Void | `sudo xbps-install bash` |
| Gentoo | déjà une dépendance classique du profil (`emerge bash` si besoin) |
| macOS | Bash 3.x par défaut — pour Bash 5 : `brew install bash` |

---

## Installation

BetterFetch ne dépend d’aucun gestionnaire de paquets spécifique : tout passe par **un fichier exécutable** dans un répertoire du `PATH`. Choisissez une méthode ci‑dessous.

### Méthode 1 — Script [`install.sh`](install.sh) (recommandée, toutes distros)

Télécharge `betterfetch.sh` depuis GitHub (**curl** ou **wget** selon ce qui est disponible) puis copie vers `PREFIX/bin/betterfetch`. Par défaut : **`~/.local/bin`** (pas besoin de `sudo`).

**Une ligne** (après publication sur `main`) :

```bash
curl -fsSL https://raw.githubusercontent.com/Impossibol04/betterfetch/main/install.sh | bash
```

Variantes :

```bash
BASE=https://raw.githubusercontent.com/Impossibol04/betterfetch/main/install.sh

# Installation utilisateur explicite (déjà le défaut)
curl -fsSL "$BASE" | bash -s -- --prefix "$HOME/.local"

# Pour tout le système (/usr/local/bin), une fois Bash installé :
curl -fsSL "$BASE" | sudo bash -s -- --system

# Branche ou tag précis (remplacer v1.0.0 par votre tag Git après release)
curl -fsSL "https://raw.githubusercontent.com/Impossibol04/betterfetch/v1.0.0/install.sh" | bash -s -- --prefix "$HOME/.local"

# Simuler sans écrire (depuis un clone)
bash install.sh --dry-run
```

Si vous n’avez pas `curl` :

```bash
wget -qO- https://raw.githubusercontent.com/Impossibol04/betterfetch/main/install.sh | bash
```

Après installation, vérifiez que `PREFIX/bin` est dans le `PATH` (souvent `~/.profile` ou `~/.bashrc`) :

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Méthode 2 — Clone Git + Makefile

```bash
git clone https://github.com/Impossibol04/betterfetch.git
cd betterfetch

make install-user              # équivalent à PREFIX=$HOME/.local
# ou
make PREFIX="$HOME/.local" install

sudo make install              # PREFIX=/usr/local → /usr/local/bin/betterfetch
```

Ou, depuis le clone, le script local **sans téléchargement réseau** :

```bash
chmod +x install.sh
./install.sh                   # utilise betterfetch.sh du même dossier
./install.sh --system          # sudo si besoin pour /usr/local
```

### Méthode 3 — Copie manuelle du script

```bash
curl -fsSL -o betterfetch https://raw.githubusercontent.com/Impossibol04/betterfetch/main/betterfetch.sh
chmod +x betterfetch
mv betterfetch ~/.local/bin/    # ou /usr/local/bin avec les droits adaptés
```

*(Les URL `raw.githubusercontent.com` supposent que le dépôt contient déjà les fichiers sur la branche `main`.)*

### Notes multi-plateforme

- **Linux** : méthodes ci-dessus.
- **macOS** : préférez Bash **4+** (`brew install bash`) puis les mêmes commandes ; certaines infos (paquets, GPU) peuvent différer.
- **BSD** : installez `bash` via le gestionnaire du système, puis comme pour Linux.

---

## Désinstallation

BetterFetch ne s’installe que comme **un exécutable** `betterfetch` (plus config/cache créés au premier lancement). La désinstallation consiste surtout à **retirer ce binaire** ; le reste est optionnel.

### Où est le binaire ?

```bash
command -v betterfetch
```

### Si vous avez installé avec le **Makefile**

`make uninstall` supprime **`$(PREFIX)/bin/betterfetch`**. Il faut utiliser **exactement le même `PREFIX` (et `DESTDIR` si vous l’aviez utilisé)** que lors de l’installation.

| Installation typique | Désinstallation |
|----------------------|-----------------|
| `sudo make install` (défaut `PREFIX=/usr/local`) | `sudo make uninstall` |
| `make install-user` ou `make PREFIX="$HOME/.local" install` | `make PREFIX="$HOME/.local" uninstall` |
| `sudo make PREFIX=/opt/betterfetch install` | `sudo make PREFIX=/opt/betterfetch uninstall` |

Exemple avec `DESTDIR` (emballage rare) :

```bash
sudo make DESTDIR=/tmp/stage PREFIX=/usr install
sudo make DESTDIR=/tmp/stage PREFIX=/usr uninstall
```

### Si vous avez installé avec **`install.sh`**

Le Makefile ne connaît pas cette installation : supprimez le fichier **à la main** selon l’option utilisée.

| Cas | Fichier à retirer |
|-----|-------------------|
| Défaut (`PREFIX` = `~/.local`) | `rm -f "$HOME/.local/bin/betterfetch"` |
| `./install.sh --prefix /chemin` | `rm -f /chemin/bin/betterfetch` |
| `./install.sh --system` (`/usr/local`) | `sudo rm -f /usr/local/bin/betterfetch` |

### Si vous avez fait une **copie manuelle** (Méthode 3)

Supprimez le fichier exactement là où vous l’avez placé, par exemple :

```bash
rm -f ~/.local/bin/betterfetch
sudo rm -f /usr/local/bin/betterfetch
```

### Config et cache (optionnel)

Ces fichiers ne sont **pas** supprimés par `make uninstall` ni par `install.sh` :

- configuration : `$XDG_CONFIG_HOME/betterfetch/` (souvent `~/.config/betterfetch/`)
- cache : `$XDG_CACHE_HOME/betterfetch_cache_$UID`

Pour tout enlever :

```bash
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/betterfetch"
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/betterfetch_cache_$UID"  # ou sous /tmp selon votre XDG_CACHE_HOME
```

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

## Développement

Vérification rapide de la syntaxe Bash :

```bash
make check
```

Optionnel : [ShellCheck](https://www.shellcheck.net/) (`pacman -S shellcheck` sur Arch), puis `shellcheck betterfetch.sh install.sh`.

---

<<<<<<< HEAD
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

> Développé avec passion ❤️ par [Impossibol](https://github.com/Impossibol04)
=======
> Développé avec passion ❤️ par [Impossibol](https://github.com/Impossibol04)
>>>>>>> 4976393 (update)
