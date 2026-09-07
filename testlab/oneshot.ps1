# oneshot.ps1 — 1 request lewat config Jhopan-Neva OneRing (hemat kuota)
$ErrorActionPreference = "Continue"
$core = "C:\Users\ACER\documents\project\onering\clash-onering\dist\mihomo.windows.amd64.onering.exe"
$testlab = "C:\Users\ACER\documents\project\onering\clash-onering\testlab"

$proc = Start-Process -FilePath $core -ArgumentList @("-d", $testlab, "-f", "$testlab\config-jhopan-neva-onering.yaml") `
    -PassThru -WindowStyle Hidden -RedirectStandardOutput "$testlab\core-out.log" -RedirectStandardError "$testlab\core-err.log"
Start-Sleep -Seconds 3

$ips = Get-NetTCPConnection -RemotePort 443 -State Established -ErrorAction SilentlyContinue |
    Where-Object { $_.OwningProcess -eq $proc.Id } | Select-Object -ExpandProperty RemoteAddress -Unique
"REMOTE_IPS: " + (($ips | Sort-Object -Unique) -join ", ")

$exitIp = & curl.exe -4 -s -x http://127.0.0.1:7894 --max-time 15 https://api.ipify.org
"EXIT_IP: $exitIp"
$r = & curl.exe -4 -s -x http://127.0.0.1:7894 --max-time 15 -o NUL -w "%{http_code} %{size_download}B %{time_total}s" https://api.ipify.org
"CHECK: $r"

Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
