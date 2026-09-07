#!/usr/bin/env bash
# trigger_or.sh — trigger trafik via instance onering (bug=support.zoom.us)
set -u
cd ~/onering-lab
MP=$(pgrep -x mihomo | head -1)
[ -z "$MP" ] && { echo "mihomo tidak jalan"; exit 1; }
: > or-wire.out
( for i in $(seq 1 26); do
    ss -tnp 2>/dev/null | grep "pid=$MP" | grep -vE '7892|9096' >> or-wire.out
    sleep 0.5
  done ) &
OBS=$!
sleep 0.5
for i in 1 2 3 4 5 6; do
  curl -s -x http://127.0.0.1:7892 --max-time 10 https://ifconfig.me -o /dev/null
  sleep 0.3
done
E4=$(curl -s -4 -x http://127.0.0.1:7892 --max-time 10 https://api.ipify.org)
wait $OBS
echo "exit IPv4 via tunnel: $E4"
echo "--- koneksi keluar yang dilihat DALAM WSL (target:port):"
grep ESTAB or-wire.out | awk '{print $5}' | sort | uniq -c | sort -rn
