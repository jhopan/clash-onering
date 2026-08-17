<div align="center">

# 💍 clash-onering

**Mihomo (Clash Meta) + OneRing SNI Patch**

*Bypass DPI — ISP hanya melihat koneksi ke CDN publik*

[![Release](https://img.shields.io/github/v/release/jhopan/clash-onering?style=for-the-badge&logo=github&color=2ea44f)](https://github.com/jhopan/clash-onering/releases)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)
[![Engine](https://img.shields.io/badge/engine-Mihomo%20v1.19.29-orange?style=for-the-badge&logo=go)](https://github.com/MetaCubeX/mihomo)
[![Platforms](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-lightgrey?style=for-the-badge)](#-download-prebuilt-binary)

```
onering:REAL_DOMAIN:BUG_DOMAIN
   │                    │
   ▼                    ▼
TLS SNI              TCP / server
(domain milikmu)     (CDN/bug gratis)
```

</div>

---

## ✨ Apa itu OneRing?

OneRing memisahkan **identitas TLS** dari **tujuan koneksi**:

```
┌─────────────────────────────────────────────────────────────────┐
│  Config:  servername = "onering:vpn.domainmu.id:support.zoom.us"│
│                              │                    │              │
│                        real domain          bug domain           │
│                              ▼                    ▼              │
│  ISP melihat ──────► support.zoom.us (CDN publik, aman)         │
│  Server menerima ──► vpn.domainmu.id (SNI asli, TLS valid)      │
└─────────────────────────────────────────────────────────────────┘
```

> 💡 **Hasil:** DPI tidak bisa memblokir koneksi VPN karena yang terlihat hanya traffic ke CDN besar (Zoom, Cloudflare, dll).

---

## 📋 Daftar Isi

- [Download](#-download-prebuilt-binary)
- [Cara Kerja](#-cara-kerja-onering)
- [Config Proxy](#️-config-proxy)
- [Config DNS](#-config-dns-wajib-baca)
- [Deploy](#-deploy)
- [Build dari Source](#️-build-dari-source)
- [Troubleshooting](#-troubleshooting)
- [Ekosistem](#-ekosistem-onering)

---

## ⬇️ Download Prebuilt Binary

**👉 [Releases](https://github.com/jhopan/clash-onering/releases)**

| File | Platform | Perangkat |
|:---|:---|:---|
| `mihomo.linux.arm64.onering` | Linux ARM64 | OpenWrt / STB / Raspberry Pi / VPS ARM |
| `mihomo.linux.amd64.onering` | Linux x64 | VPS / server / desktop Linux |
| `mihomo.linux.armv7.onering` | Linux ARMv7 | OpenWrt 32-bit / router lama |
| `mihomo.windows.amd64.onering.exe` | Windows x64 | Desktop / laptop |
| `mihomo.windows.arm64.onering.exe` | Windows ARM64 | Surface / Snapdragon PC |

```bash
# Verifikasi integritas
sha256sum -c SHA256SUMS.txt
```

---

## 🔬 Cara Kerja OneRing

Patch `ParseOneRing()` di `adapter/outbound/` — 4 baris per protocol, di-resolve sebelum koneksi TLS dibuat:

```go
// OneRing: onering:real:bug → SNI = real domain
if real, _ := ParseOneRing(option.SNI); real != "" {
    option.SNI = real
}
```

### Protocol yang Didukung

| Protocol | Config Key | Status |
|:---|:---|:---:|
| VLESS | `servername` | ✅ |
| VMess | `servername` | ✅ |
| Trojan | `sni` | ✅ |
| Hysteria | `sni` | ✅ |
| Hysteria2 | `sni` | ✅ |
| TUIC | `sni` | ✅ |

> ⚠️ **PENTING:** VLESS & VMess pakai **`servername`**, BUKAN `sni`. Key `sni:` di VLESS diabaikan diam-diam oleh Mihomo — patch tidak akan trigger. `sni` hanya valid untuk Trojan/Hysteria/Hysteria2/TUIC.

---

## ⚙️ Config Proxy

### VLESS + WebSocket + TLS

```yaml
proxies:
  - name: "vless-onering"
    type: vless
    server: support.zoom.us          # ← bug domain (TCP target)
    port: 443
    uuid: UUID-KAMU
    network: ws
    tls: true
    servername: "onering:vpn.domainmu.id:support.zoom.us"
    ws-opts:
      path: /vless
      headers:
        Host: vpn.domainmu.id
    client-fingerprint: chrome
```

### Trojan + TLS

```yaml
proxies:
  - name: "trojan-onering"
    type: trojan
    server: support.zoom.us          # ← bug domain (TCP target)
    port: 443
    password: PASSWORD
    sni: "onering:vpn.domainmu.id:support.zoom.us"
    udp: true
```

### Hysteria2

```yaml
proxies:
  - name: "hy2-onering"
    type: hysteria2
    server: support.zoom.us          # ← bug domain (TCP target)
    port: 443
    password: PASSWORD
    sni: "onering:vpn.domainmu.id:support.zoom.us"
```

### Ringkasan Field

| Field | Isi | Fungsi |
|:---|:---|:---|
| `server` | bug domain | TCP dial target (yang dilihat ISP) |
| `servername` / `sni` | `onering:REAL:BUG` | format OneRing |
| WS `Host` | real domain | header WebSocket |

---

## 🌐 Config DNS (WAJIB BACA)

> 🚨 **Salah set DNS = proxy `alive:false`.** Ini penyebab #1 kegagalan OneRing di OpenClash.

### Dua Fase DNS

```
┌────────────────────────────────────────────────────────────────────┐
│  FASE 1: BOOTSTRAP (proxy BELUM hidup)                             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ proxy-server-nameserver                                      │  │
│  │ → Resolve bug domain (support.zoom.us) untuk dial pertama    │  │
│  │ → HARUS pakai DNS yang reachable TANPA proxy                 │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  FASE 2: BROWSING (proxy SUDAH hidup)                              │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ nameserver / fallback                                        │  │
│  │ → Resolve domain browsing (google.com, youtube.com, dll)     │  │
│  │ → Keluar lewat tunnel VPN (anti DNS leak)                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

### Masalah Chicken-and-Egg

```
proxy-server-nameserver: 8.8.8.8
         │
         ▼
Proxy belum hidup → 8.8.8.8 tidak reachable
         │
         ▼
Gagal resolve support.zoom.us → proxy tidak bisa mulai 💀
```

**Solusi:** pakai `system://` (auto ikut DNS koneksi aktif) atau DNS gateway lokal.

### Config Rekomendasi

```yaml
dns:
  enable: true
  ipv6: false
  enhanced-mode: redir-host

  # ─── FASE 1: Bootstrap (sebelum proxy hidup) ───
  # system:// = auto ikut DNS koneksi aktif (modem/USB tethering/apapun)
  # Urutan TIDAK berpengaruh — semua di-query paralel, tercepat menang
  proxy-server-nameserver:
    - system://
    - 8.8.8.8
    - 1.1.1.1

  # ─── FASE 2: Browsing (setelah proxy hidup, lewat tunnel) ───
  nameserver:
    - 8.8.8.8
    - 1.1.1.1
  fallback:
    - 8.8.4.4
    - 1.0.0.1
```

### Catatan Penting

| # | Catatan |
|:---:|:---|
| 1 | **Urutan tidak berpengaruh** — Mihomo query semua server secara paralel (`batchExchange`), ambil jawaban sukses pertama |
| 2 | **`system://`** paling universal — otomatis ikut DNS gateway aktif. Ganti modem ↔ USB tethering tanpa ubah config |
| 3 | **`dhcp://<iface>`** (misal `dhcp://usb0`) juga didukung — auto-discover DNS dari DHCP interface tertentu |
| 4 | **DNS leak aman** — TUN mode hijack semua port 53 → DNS browsing keluar lewat tunnel. ISP hanya lihat 1 query bootstrap ke bug domain |
| 5 | **ISP Indonesia sering intercept DNS** — query ke IP manapun dijawab DNS operator (transparent hijack). Membantu bootstrap, tapi jangan jadikan acuan test |
| 6 | **`ipv6: false` wajib** — jika bug domain resolve IPv6-only tapi perangkat tidak punya route IPv6 → dial gagal |

---

## 🚀 Deploy

### OpenClash (OpenWrt / STB)

```bash
# 1. Upload binary (sesuaikan arsitektur)
scp dist/mihomo.linux.arm64.onering root@ROUTER:/tmp/mihomo

# 2. Replace core OpenClash
ssh root@ROUTER '
  cp /etc/openclash/core/clash_meta /etc/openclash/core/clash_meta.bak
  mv /tmp/mihomo /etc/openclash/core/clash_meta
  chmod +x /etc/openclash/core/clash_meta
  /etc/openclash/core/clash_meta version
'

# 3. Matikan auto-update core di OpenClash (kalau tidak, binary patch ketimpa)
```

### VPS / Server Linux

```bash
scp dist/mihomo.linux.amd64.onering root@SERVER:/usr/local/bin/mihomo
ssh root@SERVER 'chmod +x /usr/local/bin/mihomo && mihomo version'
```

### Windows

```bat
dist\mihomo.windows.amd64.onering.exe -d config_dir
```

---

## 🛠️ Build dari Source

### Syarat

| Syarat | Info |
|:---|:---|
| Go 1.24+ | `go version` |
| Git | clone Mihomo base |
| Internet | saat pertama `apply.sh` |
| Windows | gunakan Git Bash / WSL |

### Satu Perintah

```bash
bash build.sh --ver v1.19.29 all           # semua platform
bash build.sh --ver v1.19.29 linux-arm64   # hanya arm64
bash build.sh -v 1.19.29 windows-amd64     # Windows
bash build.sh --force --ver v1.19.30 all   # versi baru
```

### Dua Langkah

```bash
bash apply.sh v1.19.29    # unduh + patch
bash build.sh linux-arm64
```

### Semua Target

| Target | Platform | Gunakan untuk |
|:---|:---|:---|
| `host` | OS sekarang | test lokal |
| `linux-arm64` | Linux ARM64 | OpenWrt / STB / Pi / VPS ARM |
| `linux-amd64` | Linux x64 | VPS / server |
| `linux-arm` | Linux ARMv7 | OpenWrt 32-bit (GOARM=7) |
| `windows-amd64` | Windows x64 | desktop |
| `windows-arm64` | Windows ARM | Surface / Snapdragon |
| `all` | arm64+amd64+win64 | release bundle |

### Update Versi

```bash
bash apply.sh --list                          # lihat tag terbaru
bash build.sh --force --ver v1.x.y all       # build versi baru
bash verify.sh
```

<details>
<summary><b>Jika patch conflict</b></summary>

```bash
cd mihomo
git apply --reject ../onering.patch
# edit manual adapter/outbound/ per protocol
# tambah ParseOneRing call setelah SNI/serverName di-set
git add adapter/outbound/
git commit -m "OneRing"
git diff HEAD~1 adapter/outbound/ > ../onering.patch
cd .. && bash build.sh all
```

</details>

---

## 🔧 Troubleshooting

| Gejala | Penyebab | Fix |
|:---|:---|:---|
| Proxy tidak muncul di provider | YAML rusak (indentasi/quote) | Validasi YAML, pastikan indentasi 2 spasi |
| Proxy muncul tapi `alive:false` | DNS bootstrap gagal | Ganti `proxy-server-nameserver` ke `system://` |
| OneRing tidak trigger di VLESS | Pakai key `sni:` | Ganti ke **`servername:`** |
| Dial timeout | Bug domain resolve IPv6-only | Set `ipv6: false` di DNS config |
| Tiba-tiba mati | Koneksi data modem/tethering putus | Cek internet mentah dulu sebelum curiga config |
| Core ketimpa versi resmi | Auto-update OpenClash aktif | Matikan auto-update core di settings OpenClash |

### Cara Debug

```bash
# 1. Stop OpenClash, test internet mentah
/etc/init.d/openclash stop
curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://1.1.1.1

# 2. Kalau internet mentah OK, start lagi dan cek log
/etc/init.d/openclash start
cat /tmp/openclash.log | grep -iE 'error|fail|dial|lookup'

# 3. Cek proxy status via API
curl -s -H 'Authorization: Bearer SECRET' http://127.0.0.1:9090/providers/proxies
```

---

## 🌐 Ekosistem OneRing

| Repo | Engine | Config Key |
|:---|:---|:---|
| [xray-onering](https://github.com/jhopan/xray-onering) | Xray-core | `serverName` |
| [singbox-onering](https://github.com/jhopan/singbox-onering) | sing-box | `server_name` |
| **[clash-onering](https://github.com/jhopan/clash-onering)** ← kamu di sini | Mihomo/Clash | `servername` / `sni` |

---

## 📦 Isi Repo

```
clash-onering/
├── onering.patch   ← patch 6 protocol outbound (+4 baris per file)
├── onering.go      ← ParseOneRing() — file baru di adapter/outbound
├── apply.sh        ← pilih versi → clone Mihomo → apply patch
├── build.sh        ← --ver VER → apply + build binary
├── verify.sh       ← cek patch / tree / binary
├── LICENSE         ← MIT © JhopanStore
└── README.md
```

---

<div align="center">

## 📜 Credits & Lisensi

| | |
|:---|:---|
| 👨‍💻 Developer | **JhopanStore** |
| 💡 Metode OneRing | [dharak36/xray-onering](https://github.com/dharak36/xray-onering) |
| ⚙️ Engine | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) — GPL-3.0 |

**Kit ini** (patch, script, docs): **MIT License** © JhopanStore
**Binary hasil build**: mengandung Mihomo (GPL-3.0 upstream)

---

*Made with 💍 by JhopanStore*

</div>
