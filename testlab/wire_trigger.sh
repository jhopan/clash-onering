#!/usr/bin/env bash
# wire_trigger.sh — bukti kawat final: dial core = IP bug, bukan IP real
set -u
cd ~/onering-lab
MPID=$(pgrep -x mihomo | head -1)
[ -z "$MPID" ] && { echo "mihomo tidak jalan"; exit 1; }

: > wire-trigger.out
( for i in $(seq 1 20); do
    ss -tnp 2>/dev/null | grep "pid=$MPID" | grep -vE '7891|7892|9095' >> wire-trigger.out
    sleep 0.4
  done ) &
OBS=$!
sleep 0.5

echo "--- TRIGGER: 2x curl via :7891 (bug=support.zoom.us, uuid placeholder)"
curl -s -x http://127.0.0.1:7891 --max-time 8 https://ifconfig.me -o /dev/null
curl -s -x http://127.0.0.1:7891 --max-time 8 https://ifconfig.me -o /dev/null
wait $OBS

echo "--- koneksi keluar core saat trigger:"
grep ESTAB wire-trigger.out | sort -u || echo "(kosong — tidak ada dial)"
echo
echo "--- pembanding:"
echo "IP bug  support.zoom.us     : $(getent hosts support.zoom.us | awk '{print $1}' | tr '\n' ' ')"
echo "IP real neva.jhopanstore... : $(getent hosts neva.jhopanstore.my.id | awk '{print $1}')"
