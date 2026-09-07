# watch_zoom_conn.ps1 — sampling koneksi TCP ke IP bug (170.114.x) selama 15 detik
$found = @()
for ($i = 0; $i -lt 38; $i++) {
    $c = Get-NetTCPConnection -RemotePort 443 -State Established -ErrorAction SilentlyContinue |
         Where-Object { $_.RemoteAddress -like '170.114*' }
    if ($c) { $found += $c }
    Start-Sleep -Milliseconds 400
}
if ($found.Count -gt 0) {
    $u = $found | Select-Object -Unique LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
    $u | Format-Table -AutoSize | Out-String -Width 120
    $pids = ($found | Select-Object -ExpandProperty OwningProcess -Unique)
    foreach ($p in $pids) {
        $proc = Get-Process -Id $p -ErrorAction SilentlyContinue
        "PROC pid=$p name=$($proc.ProcessName) path=$($proc.Path)"
    }
    "SAMPLES_TOTAL=$($found.Count)"
} else {
    "TIDAK ADA koneksi ke 170.114.x (IP bug zoom) dalam 15 detik sampling"
}
