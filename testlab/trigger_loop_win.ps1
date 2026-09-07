# trigger_loop_win.ps1 — trigger trafik via core onering Windows (7893)
for ($i = 0; $i -lt 90; $i++) {
    curl.exe -s -x http://127.0.0.1:7893 --max-time 8 https://ifconfig.me -o NUL
    Start-Sleep -Milliseconds 400
}
"TRIGGER_DONE"
