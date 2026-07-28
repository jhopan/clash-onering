#!/usr/bin/env bash
# build.sh — build portable Mihomo/Clash OneRing binary
# Developer: JhopanStore  |  https://github.com/jhopan/clash-onering
#
#   bash build.sh --ver v1.19.29 all
#   bash build.sh -v 1.19.29 linux-arm64
#   bash build.sh host
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SRC="${SRC:-mihomo}"
DIST="${DIST:-dist}"
MH_VER_LABEL="1.19.29-onering"
LDFLAGS="${LDFLAGS:--s -w}"
MARKER="func ParseOneRing"
XVer=""
FORCE_APPLY=0
TARGETS=()

usage() {
  cat <<'EOF'
usage:
  bash build.sh [options] [target]

targets:
  host | linux-arm64 | linux-amd64 | linux-arm
  windows-amd64 | windows-arm64 | all
  custom <goos> <goarch> [extra env...]

options:
  --ver, -v VER   clone/unduh Mihomo VER + apply OneRing, lalu build
  --force, -f     re-clone base (dengan --ver)
  --help, -h

examples:
  bash build.sh --ver v1.19.29 linux-arm64
  bash build.sh -v 1.19.29 all
  bash build.sh host
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --ver|-v) shift; XVer="${1:?version required}"; shift ;;
    --force|-f) FORCE_APPLY=1; shift ;;
    --help|-h) usage; exit 0 ;;
    custom) TARGETS=("$@"); break ;;
    -*) echo "[-] unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(host)

if [ -n "$XVer" ]; then
  apply_args=("$XVer")
  [ "$FORCE_APPLY" -eq 1 ] && apply_args=(--force "$XVer")
  echo "[*] ensure base $XVer + OneRing"
  bash "$ROOT/apply.sh" "${apply_args[@]}"
  MH_VER_LABEL="${XVer#v}-onering"
fi

if [ ! -d "$SRC" ]; then
  echo "[-] $SRC missing. pakai: bash build.sh --ver v1.19.29 all" >&2
  exit 1
fi
if ! grep -q "$MARKER" "$SRC/transport/vmess/onering.go" 2>/dev/null; then
  echo "[-] OneRing belum di tree. jalankan: bash apply.sh" >&2
  exit 1
fi

base_pin=""
[ -f "$SRC/.onering-base" ] && base_pin="$(tr -d '\r\n' < "$SRC/.onering-base")"
[ -n "$base_pin" ] && echo "[*] building base=$base_pin" && MH_VER_LABEL="${base_pin#v}-onering"

mkdir -p "$DIST"

build_one() {
  local goos="$1" goarch="$2" out="$3"
  shift 3 || true
  local extra=("$@")
  echo "[*] $out  ($goos/$goarch ${extra[*]:-})"
  (
    cd "$SRC"
    env CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" ${extra[@]+"${extra[@]}"} \
      go build -trimpath \
      -ldflags="$LDFLAGS -X github.com/metacubex/mihomo/constant.Version=$MH_VER_LABEL" \
      -o "$ROOT/$DIST/$out" .
  ) && ls -lh "$ROOT/$DIST/$out" || { echo "[-] build failed: $out" >&2; return 1; }
}

do_target() {
  local target="$1"; shift || true
  case "$target" in
    host)
      local goos goarch ext=""
      goos="$(go env GOOS)"; goarch="$(go env GOARCH)"
      [ "$goos" = "windows" ] && ext=".exe"
      build_one "$goos" "$goarch" "mihomo.${goos}.${goarch}.onering${ext}"
      ;;
    linux-arm64) build_one linux arm64 mihomo.linux.arm64.onering ;;
    linux-amd64) build_one linux amd64 mihomo.linux.amd64.onering ;;
    linux-arm)   build_one linux arm mihomo.linux.armv7.onering GOARM=7 ;;
    windows-amd64) build_one windows amd64 mihomo.windows.amd64.onering.exe ;;
    windows-arm64) build_one windows arm64 mihomo.windows.arm64.onering.exe ;;
    all)
      build_one linux arm64 mihomo.linux.arm64.onering
      build_one linux amd64 mihomo.linux.amd64.onering
      build_one windows amd64 mihomo.windows.amd64.onering.exe
      ;;
    custom)
      local goos="${1:?goos}"; shift
      local goarch="${1:?goarch}"; shift
      local ext=""; [ "$goos" = "windows" ] && ext=".exe"
      build_one "$goos" "$goarch" "mihomo.${goos}.${goarch}.onering${ext}" "$@"
      ;;
    *) echo "[-] unknown target: $target" >&2; usage >&2; exit 2 ;;
  esac
}

if [ "${TARGETS[0]}" = "custom" ]; then
  do_target "${TARGETS[@]}"
else
  for t in "${TARGETS[@]}"; do do_target "$t"; done
fi

echo "[+] done → $ROOT/$DIST/"
[ -n "$base_pin" ] && echo "[+] base Mihomo $base_pin + OneRing (JhopanStore)"
ls -lh "$DIST" | sed -n '1,20p'
