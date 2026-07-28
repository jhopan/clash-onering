# clash-onering / Mihomo OneRing (JhopanStore)

Build **Mihomo (Clash Meta)** dengan patch SNI OneRing — `onering:REAL:BUG`.

- TCP / server → bug domain (CDN/host gratis)
- TLS SNI → real domain milikmu
- **2 file diubah** di Mihomo (`onering.go` baru + patch 6 protocol di `adapter/outbound`)
- Kit ini: patch + script saja — bukan fork penuh Mihomo

| | |
|---|---|
| **Developer** | **JhopanStore** |
| **Repo** | https://github.com/jhopan/clash-onering |
| **Engine base** | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) (Clash Meta) |
| **Credit metode** | [dharak36/xray-onering](https://github.com/dharak36/xray-onering) |
| **Default base** | Mihomo `v1.19.29` (bisa diganti) |
| **License kit** | MIT |

---

## Download binary (prebuilt)

> **https://github.com/jhopan/clash-onering/releases**

| File | Platform | Cocok untuk |
|---|---|---|
| `mihomo.linux.arm64.onering` | Linux ARM64 | OpenWrt / STB / Pi / VPS ARM |
| `mihomo.linux.amd64.onering` | Linux x64 | VPS / server / desktop Linux |
| `mihomo.linux.armv7.onering` | Linux ARMv7 | OpenWrt 32-bit / router lama |
| `mihomo.windows.amd64.onering.exe` | Windows x64 | Desktop / laptop Windows |
| `mihomo.windows.arm64.onering.exe` | Windows ARM64 | Surface / Snapdragon PC |
| `SHA256SUMS.txt` | — | verifikasi integritas |

```bash
sha256sum -c SHA256SUMS.txt
```

---

## Isi repo

```
clash-onering/
├── onering.patch   # patch 6 protocol (+4 baris per protocol)
├── onering.go      # ParseOneRing() — file baru di adapter/outbound
├── apply.sh        # pilih versi → clone Mihomo → apply
├── build.sh        # --ver → apply + build binary
├── verify.sh       # cek patch / binary
├── LICENSE         # MIT © JhopanStore
└── README.md
```

---

## Syarat build

- Go 1.24+
- Git
- Internet (saat pertama `apply.sh`)
- Windows: Git Bash / WSL

---

## Build

### Satu perintah

```bash
bash build.sh --ver v1.19.29 linux-arm64
bash build.sh -v 1.19.29 all
bash build.sh --force --ver v1.19.30 all
```

### Dua langkah

```bash
bash apply.sh v1.19.29
bash build.sh linux-arm64
```

### Semua platform

```bash
bash build.sh --ver v1.19.29 all
# → dist/mihomo.linux.arm64.onering
# → dist/mihomo.linux.amd64.onering
# → dist/mihomo.windows.amd64.onering.exe
```

### Target lengkap

| Target | Platform |
|---|---|
| `host` | OS sekarang |
| `linux-arm64` | OpenWrt / STB / Pi |
| `linux-amd64` | VPS / Linux |
| `linux-arm` | OpenWrt 32-bit (GOARM=7) |
| `windows-amd64` | Windows x64 |
| `windows-arm64` | Windows ARM |
| `all` | arm64+amd64 linux + win amd64 |
| `custom goos goarch` | bebas |

```bash
bash apply.sh --list          # lihat tag tersedia
bash build.sh --force --ver v1.19.30 all
bash verify.sh
```

---

## Protocol yang didukung

OneRing bekerja di **semua protocol TLS** Mihomo:

| Protocol | Config key SNI | Cover? |
|---|---|---|
| VLESS | `servername` | ✅ |
| VMess | `servername` | ✅ |
| Trojan | `sni` | ✅ |
| Hysteria | `sni` | ✅ |
| Hysteria2 | `sni` | ✅ |
| TUIC | `sni` | ✅ |

Patch ada di `adapter/outbound/` — satu `ParseOneRing()` dipakai semua protocol.

---

## Cara OneRing bekerja di Mihomo

Patch di `transport/vmess/tls.go` → `ToStdConfig()`:

```go
host := cfg.Host
// OneRing: onering:real:bug → SNI = real domain
if real, _ := ParseOneRing(host); real != "" {
    host = real
}
// host dipakai sebagai TLS ServerName
```

```
server: "support.zoom.us"
servername: "onering:neva.jhopanstore.my.id:support.zoom.us"
                         │ real                │ bug
TCP → bug domain IP (CDN)
TLS SNI → real domain
```

---

## Config Mihomo/Clash

```yaml
proxies:
  - name: "onering-vless"
    type: vless
    server: support.zoom.us
    port: 443
    uuid: UUID-MU
    network: ws
    tls: true
    servername: "onering:neva.jhopanstore.my.id:support.zoom.us"
    ws-opts:
      path: /vless
      headers:
        Host: neva.jhopanstore.my.id
    client-fingerprint: chrome
```

| Field | Value |
|---|---|
| `server` | bug domain (CDN) |
| `servername` | `onering:REAL:BUG` |
| WS `Host` | real domain |

---

## Deploy

```bash
# VPS
scp dist/mihomo.linux.amd64.onering root@SERVER:/usr/local/bin/mihomo
ssh root@SERVER 'chmod +x /usr/local/bin/mihomo && mihomo version'

# OpenWrt
scp dist/mihomo.linux.arm64.onering root@ROUTER:/tmp/mihomo

# Windows
dist\mihomo.windows.amd64.onering.exe -d config_dir
```

---

## Update ke versi Mihomo baru

```bash
bash apply.sh --list
bash build.sh --force --ver vNEW all
bash verify.sh
```

Kalau patch conflict (`ToStdConfig` berubah):

```bash
cd mihomo
git apply --reject ../onering.patch
# edit manual transport/vmess/tls.go
# tambah ParseOneRing call di ToStdConfig()
git add transport/vmess/
git commit -m "OneRing"
git diff HEAD~1 transport/vmess/tls.go > ../onering.patch
cd ..
bash build.sh all
```

---

## Perbandingan 3 repo OneRing

| | xray-onering | singbox-onering | clash-onering |
|---|---|---|---|
| Engine | Xray-core | sing-box | Mihomo/Clash |
| Patch | 1 file TLS | 3 file | 2 file |
| Config key | `serverName` | `server_name` | `servername` |
| Binary prefix | `xray.*` | `sing-box.*` | `mihomo.*` |

---

## Credits

| | |
|---|---|
| **Developer kit** | **JhopanStore** |
| **Metode OneRing** | [dharak36/xray-onering](https://github.com/dharak36/xray-onering) |
| **Engine** | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) (GPL-3.0) |

Kit (script, patch, docs) lisensi **MIT**.  
Binary mengandung Mihomo (GPL-3.0 upstream).
