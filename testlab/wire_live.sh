#!/usr/bin/env bash
# wire_live.sh — observasi koneksi live core mihomo saat trigger
# Bukti kawat: TCP dial = IP bug (zoom), bukan IP real domain
set -u
cd ~/onering-lab
OUT=wire-live.out
: > $OUT

# pastikan main instance jalan (config.yaml — bug=support.zoom.us)
if ! pgrep -x mihomo > /dev/null; then
  nohup ./mihomo -d ~/onering-lab > mihomo-run.log 2>&1 &
  sleep 3
fi
MPID=$(pgrep -x mihomo | head -1)
echo "mihomo pid=$MPID" >> $OUT

# loop observasi koneksi TCP mihomo selama trigger
( for i in $(seq 1 24); do
    ss -tnp 2>/dev/null | grep "pid=$MPID" >> $OUT
    sleep 0.5
  done ) &
OBS=$!

sleep 1
echo "=== trigger curl via :7891 (bug=support.zoom.us) ===" >> $OUT
curl -s -x http://127.0.0.1:7891 --max-time 8 https://ifconfig.me -o /dev/null 2>&1
curl -s -x http://127.0.0.1:7891 --max-time 8 https://ifconfig.me -o /dev/null 2>&1

wait $OBS

echo "=== LOG CORE (dial + tls) ===" >> $OUT
grep -oE '(dial|tls|x509)[^"]*' mihomo-run.log | tail -6 >> $OUT

echo "=== HASIL WIRE LIVE ==="
cat $OUT
echo
echo "=== pembanding: IP real domain ==="
getent hosts neva.jhopanstore.my.id
