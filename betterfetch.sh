#!/bin/bash

set -o pipefail

readonly BETTERFETCH_VERSION="1.0.0"
readonly BETTERFETCH_HOMEPAGE="https://github.com/Impossibol04/betterfetch"

bf_print_help() {
    local H=$'\033[1;33m' T=$'\033[1;36m' M=$'\033[1;32m' D=$'\033[37m' B=$'\033[1m' R=$'\033[0m'
    cat << EOF
${H}BetterFetch${R} — Infos machine à la volée (logo, infos, barre de terminal).
${D}${B}Utilisation :${R} betterfetch [options]

${M}Thème & apparence${R}
  ${T}--theme${R} <nom>         ${D}default, dracula, solarized, nord, gruvbox${R}
  ${T}--style${R} <s>         ${D}Style visuel: minimal, modern, retro, hybrid${R}
  ${T}--mode${R} <m>          ${D}normal ou compact (alias: --compact)${R}
  ${T}--no-icons${R}            ${D}Désactiver les glyphes/icônes${R}
  ${T}--ascii${R}               ${D}Forcer le mode ASCII (désactive UTF-8)${R}
  ${T}--unicode${R}             ${D}Forcer l’utilisation d’UTF-8 si disponible${R}

${M}Détail des infos${R}
  ${T}--detail${R} <n>         ${D}balanced, full, ultra, dual_mode (résumé/étendu)${R}
  ${T}--full${R}                ${D}En dual_mode: forcer l’équivalent « full »${R}

${M}Logo${R}
  ${T}--logo${R} <s>            ${D}tux, arch, none, custom (voir aussi LOGO_FILE)${R}
  ${T}--logo-file${R} <chemin>  ${D}Fichier texte du logo; impose style custom${R}

${M}Modules${R}
  ${T}--modules${R} <a,b,…>     ${D}Liste d’ordre explicite (séparateur virgule)${R}
  ${T}--enable${R} <m>          ${D}Afficher un module en plus (répétable)${R}
  ${T}--disable${R} <m>         ${D}Masquer un module (répétable)${R}
${D}  Noms reconnus (tirets acceptés) :${R}
${D}  identity, os, host_info (host), kernel, uptime,${R}
${D}  packages (package, pkg), shell, term (terminal), display,${R}
${D}  desktop, wm, theme, icons, font, cursor, cpu, gpu,${R}
${D}  mem (memory), swap, disk, disk_home (diskhome, home),${R}
${D}  network (localip), battery, locale.${R}
${D}  Dans config.conf : USE_CONFIG_MODULE_ORDER=1 pour appliquer MODULE_ORDER${R}
${D}  comme ordre final au lieu de la liste implicite du niveau de détail.${R}

${M}Palette terminal${R}
  ${T}--palette${R} <p>         ${D}Style de la bande: ansi8, ansi16, gradient,${R}
${D}                          classic, vibrant, soft (couleurs d’étiquettes)${R}
  ${T}--palette-size${R} <s>   ${D}small, medium, large (largeur des blocs)${R}
  ${T}--no-palette${R}         ${D}Ne pas afficher la bande de couleurs${R}
${D}  Compat. anciens drapeaux : --palette-basic (= ansi8, une rangée 40–47),${R}
${D}  --palette-ansi16 (deux rangées 40–47 + 100–107), --palette-gradient (256).${R}
${D}  En config, « basic » est mappé vers ansi8; le dégradé n’est pas par défaut.${R}

${M}Divers${R}
  ${T}--refresh${R}             ${D}Vider le cache (CPU, paquets, GPU, …)${R}
  ${T}--show-config${R}        ${D}Afficher le chemin du fichier config puis quitter${R}
  ${T}--version${R}, ${T}-V${R}      ${D}Version BetterFetch et bash${R}
  ${T}--help${R}, ${T}-h${R}        ${D}Cette aide${R}
EOF
}

for __bf_arg in "$@"; do
    case "$__bf_arg" in
        --version|-V) bf_early_version=1 ;;
        --help|-h) bf_early_help=1 ;;
    esac
done
if [ -n "${bf_early_version:-}" ]; then
    printf 'BetterFetch %s\n' "$BETTERFETCH_VERSION"
    printf 'bash %s\n' "$BASH_VERSION"
    [ -n "$BETTERFETCH_HOMEPAGE" ] && printf '%s\n' "$BETTERFETCH_HOMEPAGE"
    exit 0
fi
if [ -n "${bf_early_help:-}" ]; then
    bf_print_help
    exit 0
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/betterfetch"
CONFIG_FILE="$CONFIG_DIR/config.conf"
CACHE_BASE_DIR="${XDG_CACHE_HOME:-/tmp}"
CACHE_FILE="$CACHE_BASE_DIR/betterfetch_cache_$UID"
CACHE_TTL=300

mkdir -p "$CONFIG_DIR" "$CACHE_BASE_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    cat << 'EOF' > "$CONFIG_FILE"
THEME="default"
VISUAL_STYLE="modern"
MODE="normal"
DETAIL_LEVEL="dual_mode"
USE_ICONS=1
FORCE_ASCII=0
LOGO_STYLE="tux"
LOGO_FILE=""
PALETTE_STYLE="ansi8"
PALETTE_SIZE="medium"
SHOW_PALETTE=1
BAR_LENGTH=12
WRAP_LONG_VALUES=1
USE_CONFIG_MODULE_ORDER=0
MODULE_ORDER=("identity" "os" "host_info" "kernel" "uptime" "packages" "shell" "term" "display" "desktop" "wm" "theme" "icons" "font" "cursor" "cpu" "gpu" "mem" "swap" "disk" "disk_home" "network" "battery" "locale")
PKG_MANAGERS=("pacman" "dpkg" "rpm" "flatpak" "snap" "nix" "xbps" "apk")
EOF
fi

source "$CONFIG_FILE"

THEME="${THEME:-default}"
VISUAL_STYLE="${VISUAL_STYLE:-modern}"
MODE="${MODE:-normal}"
DETAIL_LEVEL="${DETAIL_LEVEL:-dual_mode}"
USE_ICONS="${USE_ICONS:-1}"
FORCE_ASCII="${FORCE_ASCII:-0}"
LOGO_STYLE="${LOGO_STYLE:-tux}"
LOGO_FILE="${LOGO_FILE:-}"
USE_CONFIG_MODULE_ORDER="${USE_CONFIG_MODULE_ORDER:-0}"
PALETTE_STYLE="${PALETTE_STYLE:-ansi8}"
case "$PALETTE_STYLE" in
    basic) PALETTE_STYLE="ansi8" ;;
esac
PALETTE_SIZE="${PALETTE_SIZE:-medium}"
SHOW_PALETTE="${SHOW_PALETTE:-1}"
BAR_LENGTH="${BAR_LENGTH:-12}"
WRAP_LONG_VALUES="${WRAP_LONG_VALUES:-1}"
if [ "${#MODULE_ORDER[@]}" -eq 0 ]; then
    MODULE_ORDER=("identity" "os" "host_info" "kernel" "uptime" "packages" "shell" "term" "display" "desktop" "wm" "theme" "icons" "font" "cursor" "cpu" "gpu" "mem" "swap" "disk" "disk_home" "network" "battery" "locale")
fi
if [ "${#PKG_MANAGERS[@]}" -eq 0 ]; then
    PKG_MANAGERS=("pacman" "dpkg" "rpm" "flatpak" "snap" "nix" "xbps" "apk")
fi

LOCALE_CTYPE="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
SUPPORTS_UTF8=0
if [[ "$LOCALE_CTYPE" == *"UTF-8"* ]] || [[ "$LOCALE_CTYPE" == *"utf8"* ]]; then
    SUPPORTS_UTF8=1
fi

FORCE_FULL=0
MODULES_FROM_CLI=0
ENABLE_MODULES=()
DISABLE_MODULES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --theme) THEME="$2"; shift 2 ;;
        --style) VISUAL_STYLE="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --compact) MODE="compact"; shift ;;
        --detail) DETAIL_LEVEL="$2"; shift 2 ;;
        --full) FORCE_FULL=1; shift ;;
        --no-icons) USE_ICONS=0; shift ;;
        --ascii) FORCE_ASCII=1; shift ;;
        --unicode) FORCE_ASCII=0; shift ;;
        --logo) LOGO_STYLE="$2"; shift 2 ;;
        --logo-file) LOGO_FILE="$2"; LOGO_STYLE="custom"; shift 2 ;;
        --modules) MODULES_FROM_CLI=1; IFS=',' read -r -a MODULE_ORDER <<< "$2"; shift 2 ;;
        --enable) ENABLE_MODULES+=("$2"); shift 2 ;;
        --disable) DISABLE_MODULES+=("$2"); shift 2 ;;
        --palette) PALETTE_STYLE="$2"; shift 2 ;;
        --palette-size) PALETTE_SIZE="$2"; shift 2 ;;
        --palette-basic) PALETTE_STYLE="ansi8"; shift ;;
        --palette-ansi16) PALETTE_STYLE="ansi16"; shift ;;
        --palette-gradient) PALETTE_STYLE="gradient"; shift ;;
        --no-palette) SHOW_PALETTE=0; shift ;;
        --refresh) rm -f "$CACHE_FILE"; shift ;;
        --show-config) echo "$CONFIG_FILE"; exit 0 ;;
        *)
            echo "Option inconnue: $1" >&2
            exit 1
            ;;
    esac
done

ASCII_MODE=0
if [ "$FORCE_ASCII" -eq 1 ] || [ "$SUPPORTS_UTF8" -eq 0 ]; then
    ASCII_MODE=1
    USE_ICONS=0
fi

sanitize_text() {
    local s="$1"
    if [ "$ASCII_MODE" -eq 1 ]; then
        echo "$s" | sed 's/█/#/g; s/▓/#/g; s/▒/=/g; s/░/-/g; s/●/*/g; s/○/o/g; s/◉/@/g; s/→/>/g; s/│/|/g; s/┆/|/g; s/─/-/g; s/•/-/g'
    else
        echo "$s"
    fi
}

set_theme() {
    case "$THEME" in
        dracula) COLOR_LOGO="\033[38;2;189;147;249m" ;;
        solarized) COLOR_LOGO="\033[38;2;38;139;210m" ;;
        nord) COLOR_LOGO="\033[38;2;136;192;208m" ;;
        gruvbox) COLOR_LOGO="\033[38;2;214;93;14m" ;;
        *) COLOR_LOGO="\033[36m" ;;
    esac
    case "$PALETTE_STYLE" in
        classic) COLOR_TITLE="\033[1;34m"; COLOR_LABEL="\033[1;34m"; COLOR_VALUE="\033[97m" ;;
        vibrant) COLOR_TITLE="\033[1;96m"; COLOR_LABEL="\033[1;95m"; COLOR_VALUE="\033[97m" ;;
        soft) COLOR_TITLE="\033[1;94m"; COLOR_LABEL="\033[36m"; COLOR_VALUE="\033[37m" ;;
        *) COLOR_TITLE="\033[1;36m"; COLOR_LABEL="\033[1;36m"; COLOR_VALUE="\033[97m" ;;
    esac
    COLOR_RESET="\033[0m"
}

apply_visual_style() {
    LOGO_WIDTH="${LOGO_WIDTH:-0}"
    case "$VISUAL_STYLE" in
        minimal) LABEL_WIDTH=9; HEADER_SEPARATOR_CHAR="-"; HEADER_SEPARATOR_WIDTH=30; BAR_FILLED="#"; BAR_EMPTY="-"; LOGO_INFO_GAP=3 ;;
        retro) LABEL_WIDTH=10; HEADER_SEPARATOR_CHAR="-"; HEADER_SEPARATOR_WIDTH=32; BAR_FILLED="#"; BAR_EMPTY="."; LOGO_INFO_GAP=2 ;;
        hybrid) LABEL_WIDTH=10; HEADER_SEPARATOR_CHAR="-"; HEADER_SEPARATOR_WIDTH=34; BAR_FILLED="#"; BAR_EMPTY="-"; LOGO_INFO_GAP=3 ;;
        modern|*) LABEL_WIDTH=10; HEADER_SEPARATOR_CHAR="="; HEADER_SEPARATOR_WIDTH=34; BAR_FILLED="#"; BAR_EMPTY="-"; LOGO_INFO_GAP=3 ;;
    esac
    [ -z "${BAR_FILLED:-}" ] && BAR_FILLED="#"
    [ -z "${BAR_EMPTY:-}" ] && BAR_EMPTY="-"
    [ "$MODE" = "compact" ] && LOGO_INFO_GAP=2
    [ "$ASCII_MODE" -eq 1 ] && HEADER_SEPARATOR_CHAR="-"
}

if [ "$USE_ICONS" -eq 1 ] && [ "$ASCII_MODE" -eq 0 ]; then
    ICON_OS=""; ICON_HOST="󰌢"; ICON_KERNEL=""; ICON_UPTIME=""; ICON_PACKAGES=""
    ICON_SHELL=""; ICON_TERM=""; ICON_DISPLAY="󰹑"; ICON_DESKTOP=""; ICON_WM="󰖲"
    ICON_THEME="󰉼"; ICON_ICONS="󰀻"; ICON_FONT=""; ICON_CURSOR="󰹑"; ICON_CPU=""
    ICON_GPU=""; ICON_MEM=""; ICON_SWAP="󰾴"; ICON_DISK=""; ICON_HOME=""
    ICON_NETWORK="󰀂"; ICON_BATTERY=""; ICON_LOCALE="󰗊"
else
    ICON_OS=""; ICON_HOST=""; ICON_KERNEL=""; ICON_UPTIME=""; ICON_PACKAGES=""
    ICON_SHELL=""; ICON_TERM=""; ICON_DISPLAY=""; ICON_DESKTOP=""; ICON_WM=""
    ICON_THEME=""; ICON_ICONS=""; ICON_FONT=""; ICON_CURSOR=""; ICON_CPU=""
    ICON_GPU=""; ICON_MEM=""; ICON_SWAP=""; ICON_DISK=""; ICON_HOME=""
    ICON_NETWORK=""; ICON_BATTERY=""; ICON_LOCALE=""
fi

module_alias() {
    case "${1,,}" in
        host) echo "host_info" ;;
        memory) echo "mem" ;;
        package|pkg) echo "packages" ;;
        diskhome|home) echo "disk_home" ;;
        terminal) echo "term" ;;
        localip) echo "network" ;;
        *) echo "${1,,}" ;;
    esac
}

make_bar() {
    local percent="$1"
    local f e
    f="${BAR_FILLED:-#}"
    e="${BAR_EMPTY:--}"
    [[ "$percent" =~ ^[0-9]+$ ]] || percent=0
    [ "$percent" -gt 100 ] && percent=100
    local filled=$(( percent * BAR_LENGTH / 100 ))
    local empty=$(( BAR_LENGTH - filled ))
    printf '%*s' "$filled" | tr ' ' "$f"
    printf '%*s' "$empty" | tr ' ' "$e"
}

wrap_value() {
    local out="" line width
    line="${1-}"
    width="${2-}"
    while [ "${#line}" -gt "$width" ] && [ "$width" -gt 15 ]; do
        split_at="$width"
        for (( i=width; i>10; i-- )); do
            if [ "${line:i:1}" = " " ]; then split_at="$i"; break; fi
        done
        out+="${line:0:$split_at}"$'\n'
        line="${line:$((split_at + 1))}"
    done
    out+="$line"
    printf "%s" "$out"
}

format_line() {
    local label="$1" value="$2" icon="$3"
    local label_pad icon_pad="" plain wrapped term_width cols indent first=1
    local lw="${LOGO_WIDTH:-0}"
    label_pad=$(printf "%-${LABEL_WIDTH}s" "$label")
    [ -n "$icon" ] && icon_pad="$icon "
    plain="$(sanitize_text "$value")"
    [ -z "$plain" ] && plain="—"
    term_width=$(tput cols 2>/dev/null || true)
    term_width=${term_width:-100}
    [ -z "$term_width" ] && term_width=100
    cols=$(( term_width - lw - ${LOGO_INFO_GAP:-3} - ${LABEL_WIDTH:-10} - 5 ))
    [ "$cols" -lt 20 ] && cols=20
    if [ "$WRAP_LONG_VALUES" -eq 1 ]; then wrapped="$(wrap_value "$plain" "$cols")"; else wrapped="$plain"; fi
    indent=$(printf "%$((LABEL_WIDTH + 2))s" "")
    while IFS= read -r ln || [ -n "$ln" ]; do
        if [ "$first" -eq 1 ]; then
            printf "%b%b%s%b\n" "${COLOR_LABEL}${icon_pad}${label_pad}${COLOR_RESET} " "${COLOR_VALUE}" "$ln" "${COLOR_RESET}"
            first=0
        else
            printf "%b%b%s%b\n" "${COLOR_LABEL}${indent}${COLOR_RESET} " "${COLOR_VALUE}" "$ln" "${COLOR_RESET}"
        fi
    done < <(printf '%s\n' "$wrapped")
}

set_logo() {
    case "$LOGO_STYLE" in
        none) logo=() ;;
        arch) logo=("       /\\       " "      /  \\      " "     / /\\ \\     " "    / ____ \\    " "   /_/    \\_\\   ") ;;
        custom)
            if [ -n "$LOGO_FILE" ] && [ -f "$LOGO_FILE" ]; then mapfile -t logo < "$LOGO_FILE"; else logo=("[logo custom introuvable]"); fi ;;
        tux|*) logo=("      .--.      " "     |o_o |     " "     |:_/ |     " "    //   \\ \\    " "   (|     | )   " "  /'\\_   _/\\_\\   " "  \\___)=(___/   ") ;;
    esac
    LOGO_WIDTH=0
    for line in "${logo[@]}"; do [ "${#line}" -gt "$LOGO_WIDTH" ] && LOGO_WIDTH="${#line}"; done
    for (( i=0; i<${#logo[@]}; i++ )); do printf -v logo[$i] "%-${LOGO_WIDTH}s" "$(sanitize_text "${logo[$i]}")"; done
}

init_cache() {
    if [ -f "$CACHE_FILE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) )) -lt "$CACHE_TTL" ]; then
        source "$CACHE_FILE"; CACHE_HIT=1
    else
        CACHE_HIT=0
    fi
}
save_cache() {
    { printf 'CACHED_CPU_MODEL=%q\n' "${CACHED_CPU_MODEL:-}"; printf 'CACHED_GPU=%q\n' "${CACHED_GPU:-}"; printf 'CACHED_PACKAGES=%q\n' "${CACHED_PACKAGES:-}"; } > "$CACHE_FILE"
}

get_disk_line() {
    local path="$1"
    line=$(df -hT "$path" 2>/dev/null | awk 'NR==2 {print $4 "|" $3 "|" $6 "|" $2}')
    if [ -n "$line" ]; then
        u="${line%%|*}"; line="${line#*|}"; t="${line%%|*}"; line="${line#*|}"; p="${line%%|*}"; fs="${line#*|}"
        echo "${u} / ${t} (${p}) - ${fs}"
    else
        echo "Indisponible"
    fi
}

declare -A data
set_theme
apply_visual_style
init_cache
data["user"]="${USER:-$(whoami 2>/dev/null)}"
data["host"]="${HOSTNAME:-$(hostname 2>/dev/null)}"
if [ -f /etc/os-release ]; then data["os"]=$(awk -F= '/^PRETTY_NAME=/{gsub(/"/, "", $2); print $2; exit}' /etc/os-release); else data["os"]="$(uname -s) $(uname -r)"; fi
hv=$(tr -d '\0' < /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null); hm=$(tr -d '\0' < /sys/devices/virtual/dmi/id/product_name 2>/dev/null)
data["host_info"]="${hv} ${hm}"; [ -z "${data["host_info"]// }" ] && data["host_info"]="${data["host"]}"
data["kernel"]="$(uname -srmo)"
up=$(awk '{print int($1)}' /proc/uptime 2>/dev/null); d=$((up/86400)); h=$(((up%86400)/3600)); m=$(((up%3600)/60)); [ "$d" -gt 0 ] && data["uptime"]="${d}d ${h}h ${m}m" || data["uptime"]="${h}h ${m}m"

if [ "$CACHE_HIT" -eq 1 ] && [ -n "${CACHED_PACKAGES:-}" ]; then data["packages"]="$CACHED_PACKAGES"; else
    pc="0"; pm="unknown"
    for mgr in "${PKG_MANAGERS[@]}"; do
        case "$mgr" in
            pacman) command -v pacman >/dev/null 2>&1 && pc=$(pacman -Q 2>/dev/null | wc -l) && pm="pacman" && break ;;
            dpkg) command -v dpkg-query >/dev/null 2>&1 && pc=$(dpkg-query -f '.' -W 2>/dev/null | wc -c) && pm="dpkg" && break ;;
            rpm) command -v rpm >/dev/null 2>&1 && pc=$(rpm -qa 2>/dev/null | wc -l) && pm="rpm" && break ;;
            flatpak) command -v flatpak >/dev/null 2>&1 && pc=$(flatpak list 2>/dev/null | wc -l) && pm="flatpak" && break ;;
            snap) command -v snap >/dev/null 2>&1 && pc=$(snap list 2>/dev/null | wc -l) && pm="snap" && break ;;
            nix) command -v nix-store >/dev/null 2>&1 && pc=$(nix-store -q --requisites /run/current-system 2>/dev/null | wc -l) && pm="nix" && break ;;
        esac
    done
    data["packages"]="${pc} (${pm})"; CACHED_PACKAGES="${data["packages"]}"
fi

sname="$(basename "${SHELL:-/bin/sh}")"; sver="$("$sname" --version 2>/dev/null | awk 'NR==1 {print $NF}')"; data["shell"]="$sname${sver:+ $sver}"
data["term"]="${TERM_PROGRAM:-${TERM:-unknown}}"
if command -v xrandr >/dev/null 2>&1; then data["display"]=$(xrandr --current 2>/dev/null | awk '/ connected/{print $1 " " $3; exit}'); fi
[ -z "${data["display"]}" ] && data["display"]="${XDG_CURRENT_DESKTOP:-N/A} (${XDG_SESSION_TYPE:-unknown})"
data["desktop"]="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-Unknown}}"
wm="${data["desktop"]}"; [ -n "${WAYLAND_DISPLAY:-}" ] && wm="${wm} (Wayland)"; [ -n "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && wm="${wm} (X11)"; data["wm"]="$wm"
if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    data["theme"]=$(awk -F= '/^gtk-theme-name/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' "$HOME/.config/gtk-3.0/settings.ini")
    data["icons"]=$(awk -F= '/^gtk-icon-theme-name/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' "$HOME/.config/gtk-3.0/settings.ini")
    data["cursor"]=$(awk -F= '/^gtk-cursor-theme-name/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' "$HOME/.config/gtk-3.0/settings.ini")
fi
[ -z "${data["theme"]}" ] && data["theme"]="Non détecté"
[ -z "${data["icons"]}" ] && data["icons"]="Non détecté"
[ -z "${data["cursor"]}" ] && data["cursor"]="Non détecté"
data["font"]=$(fc-match 2>/dev/null | awk -F: '{print $1; exit}'); [ -z "${data["font"]}" ] && data["font"]="Non détecté"

if [ "$CACHE_HIT" -eq 1 ] && [ -n "${CACHED_CPU_MODEL:-}" ]; then data["cpu"]="$CACHED_CPU_MODEL"; else
    cm=$(awk -F: '/model name/{sub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null)
    cc=$(nproc 2>/dev/null); ar=$(uname -m); fr=$(awk '/cpu MHz/{printf "%.2f GHz", $4/1000; exit}' /proc/cpuinfo 2>/dev/null)
    data["cpu"]="${cm:-Inconnu} (${cc:-?}c, ${ar}${fr:+, $fr})"; CACHED_CPU_MODEL="${data["cpu"]}"
fi
if [ "$CACHE_HIT" -eq 1 ] && [ -n "${CACHED_GPU:-}" ]; then data["gpu"]="$CACHED_GPU"; else
    if command -v lspci >/dev/null 2>&1; then data["gpu"]=$(lspci 2>/dev/null | awk -F': ' '/VGA|3D/{print $3; exit}'); fi
    [ -z "${data["gpu"]}" ] && data["gpu"]="Non détecté"; CACHED_GPU="${data["gpu"]}"
fi

read -r mt mu st su < <(free -m 2>/dev/null | awk '/^Mem:/ {m1=$2; m2=$3} /^Swap:/ {s1=$2; s2=$3} END {print m1, m2, s1, s2}')
if [[ "$mt" =~ ^[0-9]+$ ]] && [ "$mt" -gt 0 ]; then mp=$(( mu * 100 / mt )); data["mem"]="${mu} MiB / ${mt} MiB (${mp}%) [$(make_bar "$mp")]"; fi
if [[ "$st" =~ ^[0-9]+$ ]] && [ "$st" -gt 0 ]; then sp=$(( su * 100 / st )); data["swap"]="${su} MiB / ${st} MiB (${sp}%) [$(make_bar "$sp")]"; else data["swap"]="Désactivé"; fi
data["disk"]="$(get_disk_line "/")"; data["disk_home"]="$(get_disk_line "$HOME")"
iface=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}'); if [ -n "$iface" ]; then lip=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{split($4,a,"/"); print a[1]; exit}'); data["network"]="${lip:-N/A} (${iface})"; else data["network"]="Pas de réseau"; fi
bpath=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | awk 'NR==1{print; exit}')
if [ -n "$bpath" ] && [ -d "$bpath" ]; then read -r bc < "$bpath/capacity" 2>/dev/null || bc=""; read -r bs < "$bpath/status" 2>/dev/null || bs=""; data["battery"]="${bc:-?}% (${bs:-Inconnu})"; else data["battery"]="Aucune batterie"; fi
data["locale"]="${LANG:-unknown}"
save_cache

declare -A MODULE_LABEL=(
    [os]="OS:" [host_info]="Host:" [kernel]="Kernel:" [uptime]="Uptime:" [packages]="Packages:" [shell]="Shell:" [term]="Terminal:"
    [display]="Display:" [desktop]="DE:" [wm]="WM:" [theme]="Theme:" [icons]="Icons:" [font]="Font:" [cursor]="Cursor:"
    [cpu]="CPU:" [gpu]="GPU:" [mem]="Memory:" [swap]="Swap:" [disk]="Disk (/):" [disk_home]="Disk (home):"
    [network]="Local IP:" [battery]="Battery:" [locale]="Locale:"
)
declare -A MODULE_ICON=(
    [os]="$ICON_OS" [host_info]="$ICON_HOST" [kernel]="$ICON_KERNEL" [uptime]="$ICON_UPTIME" [packages]="$ICON_PACKAGES"
    [shell]="$ICON_SHELL" [term]="$ICON_TERM" [display]="$ICON_DISPLAY" [desktop]="$ICON_DESKTOP" [wm]="$ICON_WM"
    [theme]="$ICON_THEME" [icons]="$ICON_ICONS" [font]="$ICON_FONT" [cursor]="$ICON_CURSOR" [cpu]="$ICON_CPU"
    [gpu]="$ICON_GPU" [mem]="$ICON_MEM" [swap]="$ICON_SWAP" [disk]="$ICON_DISK" [disk_home]="$ICON_HOME"
    [network]="$ICON_NETWORK" [battery]="$ICON_BATTERY" [locale]="$ICON_LOCALE"
)
declare -A MODULE_VISIBLE=(
    [identity]=1 [os]=1 [host_info]=1 [kernel]=1 [uptime]=1 [packages]=1 [shell]=1 [term]=1 [display]=1 [desktop]=1 [wm]=1 [theme]=1 [icons]=1 [font]=1 [cursor]=1 [cpu]=1 [gpu]=1 [mem]=1 [swap]=1 [disk]=1 [disk_home]=1 [network]=1 [battery]=1 [locale]=1
)

EFFECTIVE_DETAIL="$DETAIL_LEVEL"
if [ "$DETAIL_LEVEL" = "dual_mode" ]; then [ "$FORCE_FULL" -eq 1 ] && EFFECTIVE_DETAIL="full" || EFFECTIVE_DETAIL="balanced"; fi
case "$EFFECTIVE_DETAIL" in
    balanced) DETAIL_MODULE_ORDER=("identity" "os" "kernel" "uptime" "shell" "term" "desktop" "theme" "cpu" "gpu" "mem" "disk" "packages" "battery" "network") ;;
    full) DETAIL_MODULE_ORDER=("identity" "os" "host_info" "kernel" "uptime" "packages" "shell" "term" "display" "desktop" "wm" "theme" "icons" "font" "cpu" "gpu" "mem" "swap" "disk" "disk_home" "network" "battery" "locale") ;;
    ultra) DETAIL_MODULE_ORDER=("identity" "os" "host_info" "kernel" "uptime" "packages" "shell" "term" "display" "desktop" "wm" "theme" "icons" "font" "cursor" "cpu" "gpu" "mem" "swap" "disk" "disk_home" "network" "battery" "locale") ;;
    *) DETAIL_MODULE_ORDER=("${MODULE_ORDER[@]}") ;;
esac
if [ "$MODULES_FROM_CLI" -eq 1 ] || [ "${USE_CONFIG_MODULE_ORDER:-0}" -eq 1 ]; then
    if [ "${#MODULE_ORDER[@]}" -gt 0 ]; then
        DETAIL_MODULE_ORDER=("${MODULE_ORDER[@]}")
    fi
fi
for m in "${ENABLE_MODULES[@]}"; do m="$(module_alias "$m")"; MODULE_VISIBLE["$m"]=1; found=0; for x in "${DETAIL_MODULE_ORDER[@]}"; do [ "$x" = "$m" ] && found=1; done; [ "$found" -eq 0 ] && DETAIL_MODULE_ORDER+=("$m"); done
for m in "${DISABLE_MODULES[@]}"; do m="$(module_alias "$m")"; MODULE_VISIBLE["$m"]=0; done

set_logo

infos=()
identity="${data["user"]}@${data["host"]}"
infos+=("${COLOR_TITLE}$(sanitize_text "$identity")${COLOR_RESET}")
infos+=("${COLOR_LABEL}$(printf '%*s' "$HEADER_SEPARATOR_WIDTH" | tr ' ' "$HEADER_SEPARATOR_CHAR")${COLOR_RESET}")
for m in "${DETAIL_MODULE_ORDER[@]}"; do
    m="$(module_alias "$m")"
    [ "$m" = "identity" ] && continue
    [ "${MODULE_VISIBLE[$m]:-0}" -eq 0 ] && continue
    [ -n "${MODULE_LABEL[$m]:-}" ] && [ -n "${data[$m]:-}" ] && infos+=("$(format_line "${MODULE_LABEL[$m]}" "${data[$m]}" "${MODULE_ICON[$m]}")")
done

max_lines=$(( ${#logo[@]} > ${#infos[@]} ? ${#logo[@]} : ${#infos[@]} ))
spacer=$(printf '%*s' "$LOGO_INFO_GAP")
blank_logo=$(printf '%*s' "$LOGO_WIDTH")
    for (( i=0; i<max_lines; i++ )); do
    ll="${logo[$i]:-$blank_logo}"
    li="${infos[$i]:-}"
    if [ "${#logo[@]}" -gt 0 ]; then echo -e "${COLOR_LOGO}${ll}${COLOR_RESET}${spacer}${li}"; else echo -e "${li}"; fi
done

print_palette_ansi8() {
    case "$PALETTE_SIZE" in small) block=" " ;; large) block="   " ;; *) block="  " ;; esac
    offset=""
    [ "${#logo[@]}" -gt 0 ] && offset=$(printf '%*s' $(( LOGO_WIDTH + LOGO_INFO_GAP )))
    printf "%s" "$offset"
    for c in 40 41 42 43 44 45 46 47; do printf "\033[%sm%s\033[0m" "$c" "$block"; done
    echo ""
}
print_palette_ansi16() {
    case "$PALETTE_SIZE" in small) block=" " ;; large) block="   " ;; *) block="  " ;; esac
    offset=""
    [ "${#logo[@]}" -gt 0 ] && offset=$(printf '%*s' $(( LOGO_WIDTH + LOGO_INFO_GAP )))
    printf "%s" "$offset"
    for c in 40 41 42 43 44 45 46 47; do printf "\033[%sm%s\033[0m" "$c" "$block"; done
    echo ""
    printf "%s" "$offset"
    for c in 100 101 102 103 104 105 106 107; do printf "\033[%sm%s\033[0m" "$c" "$block"; done
    echo ""
}
print_palette_gradient() { offset=""; [ "${#logo[@]}" -gt 0 ] && offset=$(printf '%*s' $(( LOGO_WIDTH + LOGO_INFO_GAP ))); printf "%s" "$offset"; for c in {16..51}; do printf "\033[48;5;%dm  \033[0m" "$c"; done; echo ""; }

if [ "$SHOW_PALETTE" -eq 1 ]; then
    echo ""
    case "$PALETTE_STYLE" in
        gradient) [ "$ASCII_MODE" -eq 0 ] && print_palette_gradient || print_palette_ansi8 ;;
        ansi16) print_palette_ansi16 ;;
        ansi8|classic|vibrant|soft|*) print_palette_ansi8 ;;
    esac
fi
echo ""
exit 0
