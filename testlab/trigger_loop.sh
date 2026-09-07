#!/usr/bin/env bash
# trigger_loop.sh — trigger trafik onering (bug=support.zoom.us) 60 detik
for i in $(seq 1 90); do
  curl -s -x http://127.0.0.1:7892 --max-time 8 https://ifconfig.me -o /dev/null
  sleep 0.4
done
echo TRIGGER_DONE
