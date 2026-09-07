# run_zoomonly.ps1 — uji terpinned Wi-Fi: counters per-interface + exit IP
# param 1 = config path, param 2 = label
param(
    [Parameter(Mandatory=$true)][string]$ConfigPath,
    [Parameter(Mandatory=$true)][string]$Label
)
$ErrorActionPreference = "Continue"
$core = "C:\Users\ACER\documents\project\onering\clash-onering\dist\mihomo.windows.amd64.onering.exe"

function Snap($names) {
    $s = @{}
    foreach ($n in $names) {
        $a = Get-NetAdapterStatistics -Name $n -ErrorAction SilentlyContinue
        if ($a) { $s[$n] = @{ Rx = $a.ReceivedBytes; Tx = $a.SentBytes } }
    }
    return $s
}
$ifaces = @("Wi-Fi", "Ethernet 5")
$before = Snap $ifaces

# core start
$proc = Start-Process -FilePath $core -ArgumentList @(
    "-d", "C:\Users\ACER\documents\project\onering\clash-onering\testlab",
    "-f", $ConfigPath
) -PassThru -WindowStyle Hidden -RedirectStandardOutput "C:\Users\ACER\documents\project\onering\clash-onering\testlab\core-out.log" -RedirectStandardError "C:\Users\ACER\documents\project\onering\clash-onering\testlab\core-err.log"
Start-Sleep -Seconds 3

# koneksi netstat 3x sample
$samples = @()
for ($i=0; $i -lt 3; $i++) {
    $samples += (Get-NetTCPConnection -RemotePort 443 -State Established -ErrorAction SilentlyContinue |
        Where-Object { $_.OwningProcess -eq $proc.Id } |
        Select-Object -ExpandProperty RemoteAddress -Unique)
    Start-Sleep -Milliseconds 200
}
"REMOTE_IPS_SEEN: " + (($samples | Sort-Object -Unique) -join ", ")

# trigger 15 request + exit IP
$exits = @()
for ($i=0; $i -lt 15; $i++) {
    $r = & curl.exe -4 -s -x http://127.0.0.1:7893 --max-time 12 https://api.ipify.org 2>$null
    if ($r) { $exits += $r }
    Start-Sleep -Milliseconds 300
}
"EXIT_IPS: " + (($exits | Sort-Object -Unique) -join ", ") + "  (n=$($exits.Count)/15)"

Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$after = Snap $ifaces
"=== DELTA BYTE per interface ($Label) ==="
foreach ($n in $ifaces) {
    if ($before.ContainsKey($n) -and $after.ContainsKey($n)) {
        $drx = $after[$n].Rx - $before[$n].Rx
        $dtx = $after[$n].Tx - $before[$n].Tx
        "{0,-12} RX={1,10:N0}  TX={2,10:N0}" -f $n, $drx, $dtx
    }
}
"=== core log tail ==="
Get-Content "C:\Users\ACER\documents\project\onering\clash-onering\testlab\core-out.log" -Tail 5 -ErrorAction SilentlyContinue
