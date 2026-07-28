#!/usr/bin/env bash
# apply.sh — pilih versi Mihomo/Clash → clone → apply patch OneRing
# Developer: JhopanStore  |  https://github.com/jhopan/clash-onering
#
#   bash apply.sh
#   bash apply.sh v1.19.29
#   bash apply.sh --force v1.19.29
#   bash apply.sh --list
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

OUT_DIR="${OUT_DIR:-mihomo}"
PATCH="${PATCH:-onering.patch}"
ONERING_GO="${ONERING_GO:-onering.go}"
DEFAULT_VER="v1.19.29"
MARKER="func ParseOneRing"
FORCE=0
MH_VER="${MH_VER:-}"

usage() {
  cat <<'EOF'
usage:
  bash apply.sh [options] [version]

options:
  --force, -f     re-clone even if tree exists
  --list, -l      list recent Mihomo tags
  --help, -h

version:
  Mihomo tag, e.g. v1.19.29  (default: v1.19.29)

env:
  MH_VER=...  OUT_DIR=...  PATCH=...
EOF
}

list_tags() {
  echo "[*] recent Mihomo/Clash tags..."
  git ls-remote --tags --refs https://github.com/MetaCubeX/mihomo.git 2>/dev/null \
    | awk -F/ '{print $NF}' | grep -v '\^{}' | sort -V | tail -20 || true
}

while [ $# -gt 0 ]; do
  case "$1" in
    --force|-f) FORCE=1; shift ;;
    --list|-l) list_tags; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    -*) echo "[-] unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) MH_VER="$1"; shift ;;
  esac
done

MH_VER="${MH_VER:-$DEFAULT_VER}"
case "$MH_VER" in v*) ;; *) MH_VER="v$MH_VER" ;; esac

if [ ! -f "$PATCH" ] || [ ! -f "$ONERING_GO" ]; then
  echo "[-] missing $PATCH or $ONERING_GO" >&2
  exit 1
fi

need_clone=0
if [ "$FORCE" -eq 1 ]; then
  need_clone=1
elif [ ! -d "$OUT_DIR/.git" ]; then
  need_clone=1
else
  pinned=""
  [ -f "$OUT_DIR/.onering-base" ] && pinned="$(tr -d '\r\n' < "$OUT_DIR/.onering-base")"
  if [ -n "$pinned" ] && [ "$pinned" != "$MH_VER" ]; then
    echo "[*] base pin $pinned → $MH_VER (re-clone)"
    need_clone=1
  fi
fi

if [ "$need_clone" -eq 1 ]; then
  echo "[*] clone Mihomo $MH_VER → $OUT_DIR"
  rm -rf "$OUT_DIR"
  if ! git clone --depth 1 --branch "$MH_VER" https://github.com/MetaCubeX/mihomo.git "$OUT_DIR"; then
    echo "[-] clone gagal. cek tag: bash apply.sh --list" >&2
    exit 1
  fi
else
  echo "[*] $OUT_DIR ada (base $MH_VER) — skip clone"
fi

echo "$MH_VER" > "$OUT_DIR/.onering-base"

TLS_DIR="$OUT_DIR/transport/vmess"
ONERING_DST="$TLS_DIR/onering.go"

if [ ! -d "$TLS_DIR" ]; then
  echo "[-] missing $TLS_DIR" >&2
  exit 1
fi

if grep -q "$MARKER" "$ONERING_DST" 2>/dev/null; then
  echo "[+] OneRing already applied. skip."
else
  echo "[*] copy onering.go → $ONERING_DST"
  cp "$ROOT/$ONERING_GO" "$ONERING_DST"

  echo "[*] apply $PATCH"
  if ! git -C "$OUT_DIR" apply --whitespace=nowarn "$ROOT/$PATCH"; then
    echo "[-] git apply failed for base $MH_VER" >&2
    echo "    try: git -C $OUT_DIR apply --reject $ROOT/$PATCH" >&2
    rm -f "$ONERING_DST"
    exit 1
  fi
  grep -q "$MARKER" "$ONERING_DST" || { echo "[-] verify failed"; exit 1; }
  echo "[+] OneRing patch applied"
fi

echo "[+] core ready: $ROOT/$OUT_DIR  (base=$MH_VER)"
echo "[+] next: bash build.sh [target]  |  bash build.sh --ver $MH_VER all"
