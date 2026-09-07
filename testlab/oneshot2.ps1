# oneshot2.ps1 — 1 request via fake-SNI zoom, server = IP VPS hardcoded (TANPA DNS)
$ErrorActionPreference = "Continue"
$core = "C:\Users\ACER\documents\project\onering\clash-onering\dist\mihomo.windows.amd64.onering.exe"
$testlab = "C:\Users\ACER\documents\project\onering\clash-onering\testlab"

Get-Process mihomo* -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

$proc = Start-Process -FilePath $core -ArgumentList @("-d", $testlab, "-f", "$testlab\config-fakesni-zoom.yaml") `
    -PassThru -WindowStyle Hidden -RedirectStandardOutput "$testlab\core-out.log" -RedirectStandardError "$testlab\core-err.log"
Start-Sleep -Seconds 3

$ips = Get-NetTCPConnection -RemotePort 443 -State Established -ErrorAction SilentlyContinue |
    Where-Object { $_.OwningProcess -eq $proc.Id } | Select-Object -ExpandProperty RemoteAddress -Unique
"REMOTE_IPS (harus IP VPS 103.169.207.207, bukan zoom): " + (($ips | Sort-Object -Unique) -join ", ")

$exitIp = & curl.exe -4 -s -x http://127.0.0.1:7894 --max-time 15 https://api.ipify.org
"EXIT_IP: $exitIp"
$r = & curl.exe -4 -s -x http://127.0.0.1:7894 --max-time 15 -o NUL -w "%{http_code} %{size_download}B %{time_total}s" https://api.ipify.org
"CHECK: $r"

Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
