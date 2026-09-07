#!/usr/bin/env bash
# wire_test.sh — uji kawat OneRing (mihomo clash-onering) tanpa root
# Rangkaian: DNS zoom, TCP+CH zoom, TLS real, CH listener lokal
# Semua output ke ~/onering-lab/wire-test.out
set -u
cd ~/onering-lab
OUT=wire-test.out
: > $OUT

cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/config.yaml .
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/config-local.yaml .
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/sni_proof.py .

pkill -f 'config-local' 2>/dev/null
pkill -f 'sni_proof.py' 2>/dev/null
sleep 1

{
echo "### [1] DNS kawat — resolve bug domain support.zoom.us"
dig +short support.zoom.us 2>/dev/null || getent hosts support.zoom.us
echo
echo "### [2] TCP kawat — dial langsung ke IP bug:443 (telnet-style)"
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/support.zoom.us/443' \
  && echo "TCP connect support.zoom.us:443 OK" || echo "TCP connect FAILED"
} >> $OUT 2>&1 &

{
echo "### [3] TLS ke real domain — SNI real harus valid di server asli"
echo | timeout 10 openssl s_client -connect neva.jhopanstore.my.id:443 \
  -servername neva.jhopanstore.my.id 2>/dev/null | grep -E 'subject=|Verify return code'
} >> $OUT 2>&1

wait

{
echo "### [4] CH listener lokal — isi ClientHello saat core dial bug lokal"
python3 sni_proof.py 2>&1
} > sni_proof_side.out 2>&1 &
LPID=$!
sleep 1

{
echo "### [5] Core ON — trigger via instance lokal (7892)"
nohup ./mihomo -d ~/onering-lab -f config-local.yaml > mihomo-local.log 2>&1 &
MPID=$!
sleep 3
curl -s -x http://127.0.0.1:7892 --max-time 6 https://example.com/ -o /dev/null 2>/dev/null
sleep 1
kill $MPID 2>/dev/null
echo "trigger done"
} >> $OUT 2>&1

wait $LPID
cat sni_proof_side.out >> $OUT

echo "=== HASIL ==="
cat $OUT
