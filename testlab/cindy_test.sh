#!/usr/bin/env bash
# cindy_test.sh — uji end-to-end URI user: baseline vs OneRing variant
set -u
cd ~/onering-lab
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/config-cindy.yaml .
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/config-cindy-onering.yaml .

pkill -x mihomo 2>/dev/null
sleep 1

run_baseline() {
  ./mihomo -d ~/onering-lab -f config-cindy.yaml > mihomo-cindy.log 2>&1 &
  MP=$!
  sleep 3
  echo "=== [BASELINE] server=neva SNI=neva (URI asli) ==="
  echo "--- dial target (ss, saat trigger):"
  ( for i in $(seq 1 16); do ss -tnp 2>/dev/null | grep "pid=$MP" | grep -vE '7891|7892|9095'; sleep 0.4; done ) & OBS=$!
  sleep 0.5
  R=$(curl -s -x http://127.0.0.1:7891 --max-time 12 https://ifconfig.me 2>&1)
  wait $OBS
  echo "--- curl via :7891 https://ifconfig.me => [$R]"
  echo "--- log core (error/warn):"
  grep -oE '(level=(error|warning))[^"]*' mihomo-cindy.log | head -5
  kill $MP 2>/dev/null
}

run_onering() {
  ./mihomo -d ~/onering-lab -f config-cindy-onering.yaml > mihomo-cindy-or.log 2>&1 &
  MP=$!
  sleep 3
  echo
  echo "=== [ONERING] server=zoom SNI=onering:neva:zoom ==="
  echo "--- dial target (ss, saat trigger):"
  ( for i in $(seq 1 16); do ss -tnp 2>/dev/null | grep "pid=$MP" | grep -vE '7891|7892|9096'; sleep 0.4; done ) & OBS=$!
  sleep 0.5
  R=$(curl -s -x http://127.0.0.1:7892 --max-time 12 https://ifconfig.me 2>&1)
  wait $OBS
  echo "--- curl via :7892 https://ifconfig.me => [$R]"
  echo "--- log core (error/warn):"
  grep -oE '(level=(error|warning))[^"]*' mihomo-cindy-or.log | head -5
  kill $MP 2>/dev/null
}

run_baseline
run_onering
echo
echo "--- referensi IP:"
echo "neva (real): $(getent hosts neva.jhopanstore.my.id 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
python3 - <<'PY'
import socket
try:
    print("zoom (bug) :", ", ".join(sorted({i[4][0] for i in socket.getaddrinfo("support.zoom.us", 443, socket.AF_INET))}))
except Exception as e:
    print("zoom resolve fail:", e)
PY
