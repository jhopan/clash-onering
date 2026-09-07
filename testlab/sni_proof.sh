#!/usr/bin/env bash
# sni_proof.sh — bukti OneRing SNI override di mihomo (clash-onering)
# Instance kedua (port 7892/9096) dial 127.0.0.1:8443 (listener bukan TLS server).
# Listener capture ClientHello → SNI harus "neva.jhopanstore.my.id".
set -u
cd ~/onering-lab

pkill -f sni_proof.py 2>/dev/null
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/config-local.yaml config-local.yaml
cp /mnt/c/Users/ACER/documents/project/onering/clash-onering/testlab/sni_proof.py sni_proof.py

python3 sni_proof.py > sni_proof.out 2>&1 &
LPID=$!
sleep 1

pkill -f 'mihomo.*config-local' 2>/dev/null
nohup ./mihomo -d ~/onering-lab -f config-local.yaml > mihomo-local.log 2>&1 &
MPID=$!
sleep 3

# trigger: curl via instance kedua → core dial 127.0.0.1:8443 + kirim ClientHello
curl -s -x http://127.0.0.1:7892 --max-time 6 https://example.com/ -o /dev/null 2>/dev/null
sleep 1
kill $MPID 2>/dev/null
kill $LPID 2>/dev/null

echo "=== mihomo-local.log (tail) ==="
tail -5 mihomo-local.log
echo "=== sni_proof.out ==="
cat sni_proof.out
