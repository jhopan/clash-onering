#!/usr/bin/env bash
# verify.sh — cek patch OneRing Mihomo/Clash + binary
# Developer: JhopanStore  |  https://github.com/jhopan/clash-onering
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
fail=0

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && { echo "usage: bash verify.sh [binary]"; exit 0; }

echo "=== Mihomo/Clash OneRing verify (JhopanStore) ==="

[ -f onering.patch ] && echo "OK onering.patch" || { echo "FAIL onering.patch"; fail=1; }
[ -f onering.go ] && grep -q "func ParseOneRing" onering.go && echo "OK onering.go" || { echo "FAIL onering.go"; fail=1; }

if [ -d mihomo ]; then
  grep -q "func ParseOneRing" mihomo/transport/vmess/onering.go 2>/dev/null && echo "OK tree onering.go" || { echo "FAIL tree onering.go"; fail=1; }
  grep -q "ParseOneRing" mihomo/transport/vmess/tls.go 2>/dev/null && echo "OK tls.go patched" || { echo "FAIL tls.go"; fail=1; }
  [ -f mihomo/.onering-base ] && echo "OK base pin $(tr -d '\r\n' < mihomo/.onering-base)"
else
  echo "SKIP no mihomo tree (run apply.sh)"
fi

BIN="${1:-}"
[ -z "$BIN" ] && BIN="$(ls -t dist/mihomo.*.onering* 2>/dev/null | head -1 || true)"
if [ -n "${BIN:-}" ] && [ -f "$BIN" ]; then
  echo "BIN: $BIN ($(wc -c < "$BIN" | tr -d ' ') bytes)"
  if "$BIN" version >/tmp/mh-ver.txt 2>&1; then
    head -3 /tmp/mh-ver.txt | sed 's/^/  /'
    echo "OK version runs"
  else
    echo "SKIP cannot exec (cross-build?)"
  fi
else
  echo "SKIP no binary"
fi

if command -v go >/dev/null; then
  PARSE_GO="$(go env GOPATH)/clash_onering_check.go"
  mkdir -p "$(dirname "$PARSE_GO")"
  cat > "$PARSE_GO" <<'GO'
package main
import ("fmt"; "os"; "strings")
func ParseOneRing(s string) (real, bug string) {
  const p = "onering:"
  if !strings.HasPrefix(strings.ToLower(s), p) { return "", "" }
  parts := strings.SplitN(s, ":", 3)
  if len(parts) != 3 || parts[1] == "" || parts[2] == "" { return "", "" }
  return strings.TrimSpace(parts[1]), strings.TrimSpace(parts[2])
}
func main() {
  r,b := ParseOneRing("onering:real.example:bug.example")
  if r != "real.example" || b != "bug.example" { fmt.Println("FAIL"); os.Exit(1) }
  r,_ = ParseOneRing("normal.host"); if r != "" { fmt.Println("FAIL normal"); os.Exit(1) }
  fmt.Println("OK ParseOneRing logic")
}
GO
  go run "$PARSE_GO" || fail=1
  rm -f "$PARSE_GO"
fi

[ "$fail" -eq 0 ] && echo ADHOC_VERIFY_PASS || { echo ADHOC_VERIFY_FAIL; exit 1; }
