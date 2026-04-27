#!/usr/bin/env bash
# BetterFetch — installation universelle (Linux, *BSD, macOS avec Bash)
set -euo pipefail

BFETCH_REPO_RAW="${BFETCH_REPO_RAW:-https://raw.githubusercontent.com/Impossibol04/betterfetch}"
BFETCH_BRANCH="${BFETCH_BRANCH:-main}"

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAVE_LOCAL=""
if [[ -f "$SCRIPT_DIR/betterfetch.sh" ]] && [[ -s "$SCRIPT_DIR/betterfetch.sh" ]]; then
    HAVE_LOCAL=1
fi

PREFIX="${HOME}/.local"
DRY_RUN=0

usage() {
    printf '%s\n' "Usage: ${0##*/} [--prefix DIR] [--system] [--branch NAME] [--dry-run]" >&2
    printf '%s\n' "  Par défaut : installation utilisateur dans PREFIX/bin (défaut: ~/.local/bin)." >&2
    printf '%s\n' "  --system   équivalent à --prefix /usr/local (souvent sudo requis)." >&2
    printf '%s\n' "  --branch   branche ou tag GitHub pour le téléchargement (défaut: ${BFETCH_BRANCH})." >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            [[ -n "${2:-}" ]] || die "argument manquant pour --prefix"
            PREFIX="$2"
            shift 2
            ;;
        --system)
            PREFIX="/usr/local"
            shift
            ;;
        --branch)
            [[ -n "${2:-}" ]] || die "argument manquant pour --branch"
            BFETCH_BRANCH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h | --help)
            usage
            ;;
        *)
            die "option inconnue: $1 (essayez --help)"
            ;;
    esac
done

BINDIR="${PREFIX}/bin"
TARGET="${BINDIR}/betterfetch"

download_to() {
    local url="$1" out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$out"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$out"
    else
        die "Installez curl ou wget pour télécharger BetterFetch."
    fi
}

tmpdir=""
cleanup() {
    [[ -z "${tmpdir:-}" ]] || rm -rf "$tmpdir"
}
trap cleanup EXIT

SRC=""
if [[ -n "$HAVE_LOCAL" ]]; then
    SRC="$SCRIPT_DIR/betterfetch.sh"
else
    tmpdir=$(mktemp -d)
    SRC="${tmpdir}/betterfetch.sh"
    URL="${BFETCH_REPO_RAW}/${BFETCH_BRANCH}/betterfetch.sh"
    printf 'Téléchargement depuis %s …\n' "$URL"
    download_to "$URL" "$SRC"
fi

[[ -r "$SRC" ]] || die "Impossible de lire betterfetch.sh"

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] mkdir -p %q\n' "$BINDIR"
    printf '[dry-run] cp %q -> %q\n' "$SRC" "$TARGET"
    printf '[dry-run] chmod 755 %q\n' "$TARGET"
    exit 0
fi

mkdir -p "$BINDIR"
cp "$SRC" "$TARGET"
chmod 755 "$TARGET"

printf 'BetterFetch installé dans %s\n' "$TARGET"
printf 'Vérifiez que %s est dans votre PATH (ex. export PATH="%s/bin:$PATH").\n' "$BINDIR" "$PREFIX"
