#!/usr/bin/env bash
# sni_proof.sh — bukti packet-level OneRing SNI override (mihomo clash-onering)
# Instance kedua (7892/9096) dial bug=127.0.0.1:18443. Listener Python capture
# ClientHello mentah. SNI di kawat harus "neva.jhopanstore.my.id", tanpa "onering:".
set -u
cd ~/onering-lab
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/config-local.yaml .
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/sni_proof.py .

pkill -f 'config-local' 2>/dev/null
pkill -f 'sni_proof.py' 2>/dev/null
sleep 1

python3 sni_proof.py > sni_proof.out 2>&1 &
LPID=$!
sleep 1

nohup ./mihomo -d ~/onering-lab -f config-local.yaml > mihomo-local.log 2>&1 &
MPID=$!
sleep 3

curl -s -x http://127.0.0.1:7892 --max-time 6 https://example.com/ -o /dev/null 2>/dev/null
sleep 1
kill $MPID 2>/dev/null
kill $LPID 2>/dev/null

echo "=== mihomo-local.log (dial error = bukti kedua) ==="
grep -oE 'x509: [^"]*' mihomo-local.log | head -2
echo "=== sni_proof.out (bukti packet-level) ==="
cat sni_proof.out
