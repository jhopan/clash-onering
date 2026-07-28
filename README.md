# clash-onering

> **Mihomo (Clash Meta)** dengan patch OneRing SNI — bypass DPI tanpa domain pointing ke Cloudflare.

```
onering:REAL_DOMAIN:BUG_DOMAIN
   ↓                    ↓
TLS SNI / sni       TCP / server
(real milikmu)      (CDN/bug gratis)
```

ISP hanya melihat koneksi ke CDN publik. Server menerima TLS dengan SNI domain kamu sendiri.

---

<div align="center">

| | |
|---|---|
| 👨‍💻 **Developer** | JhopanStore |
| 🔧 **Engine** | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) (Clash Meta) |
| 💡 **Credit metode** | [dharak36/xray-onering](https://github.com/dharak36/xray-onering) |
| 📦 **Base default** | Mihomo `v1.19.29` |
| 📄 **Lisensi kit** | MIT |

</div>

---

## ⬇️ Download Prebuilt Binary

**👉 https://github.com/jhopan/clash-onering/releases**

| File | OS | Perangkat |
|---|---|---|
| `mihomo.linux.arm64.onering` | Linux ARM64 | OpenWrt / STB / Raspberry Pi / VPS ARM |
| `mihomo.linux.amd64.onering` | Linux x64 | VPS / server / desktop Linux |
| `mihomo.linux.armv7.onering` | Linux ARMv7 | OpenWrt 32-bit / router lama |
| `mihomo.windows.amd64.onering.exe` | Windows x64 | Desktop / laptop Windows |
| `mihomo.windows.arm64.onering.exe` | Windows ARM64 | Surface / Snapdragon PC |
| `SHA256SUMS.txt` | — | verifikasi integritas |

```bash
sha256sum -c SHA256SUMS.txt
```

---

## 🔬 Cara Kerja OneRing

```
Config:  servername = "onering:neva.jhopanstore.my.id:support.zoom.us"
                                ┌─────────────┘         └──────────────┐
                                │ real domain                bug domain │
                                ▼                                       ▼
         TLS SNI ──────► neva.jhopanstore.my.id    TCP ──────► support.zoom.us IP
```

Patch `ParseOneRing()` di `adapter/outbound/` — tiap protocol di-resolve sebelum koneksi TLS dibuat:

```go
// OneRing: onering:real:bug → SNI = real domain
if real, _ := ParseOneRing(option.SNI); real != "" {
    option.SNI = real
}
```

**Protocol yang didukung** (semua TLS outbound Mihomo):

| Protocol | Config key SNI | ✅ |
|---|---|---|
| VLESS | `servername` | ✅ |
| VMess | `servername` | ✅ |
| Trojan | `sni` | ✅ |
| Hysteria | `sni` | ✅ |
| Hysteria2 | `sni` | ✅ |
| TUIC | `sni` | ✅ |

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

# setelah build (gitignored):
mihomo/             ← source tree yang diunduh + dipatch
dist/               ← binary output
```

---

## 🛠️ Build dari Source

### Syarat

| Syarat | Info |
|---|---|
| Go 1.24+ | cek: `go version` |
| Git | untuk clone Mihomo base |
| Internet | saat pertama `apply.sh` |
| Windows | gunakan Git Bash atau WSL |

### Satu Perintah (Recommended)

```bash
bash build.sh --ver v1.19.29 all           # semua platform utama
bash build.sh --ver v1.19.29 linux-arm64   # hanya arm64
bash build.sh -v 1.19.29 windows-amd64    # Windows
bash build.sh --force --ver v1.19.30 all  # paksa re-clone versi baru
```

### Dua Langkah

```bash
bash apply.sh v1.19.29    # unduh + patch
bash build.sh linux-arm64
```

### Semua Target

| Target | Platform | Gunakan untuk |
|---|---|---|
| `host` | OS sekarang | test lokal |
| `linux-arm64` | Linux ARM64 | OpenWrt / STB / Pi / VPS ARM |
| `linux-amd64` | Linux x64 | VPS / server |
| `linux-arm` | Linux ARMv7 | OpenWrt 32-bit (GOARM=7) |
| `windows-amd64` | Windows x64 | desktop |
| `windows-arm64` | Windows ARM | Surface / Snapdragon |
| `all` | arm64+amd64+win64 | release bundle |
| `custom GOOS GOARCH` | bebas | macOS, FreeBSD, dll |

### Manajemen Versi

```bash
bash apply.sh --list                          # lihat tag Mihomo terbaru
bash build.sh --force --ver v1.19.30 all     # naik versi
bash verify.sh
./dist/mihomo.linux.amd64.onering version
```

---

## ⚙️ Config Mihomo/Clash

### VLESS + WebSocket + TLS

```yaml
proxies:
  - name: "vless-onering"
    type: vless
    server: support.zoom.us        # ← bug domain (CDN)
    port: 443
    uuid: UUID-KAMU
    network: ws
    tls: true
    servername: "onering:neva.jhopanstore.my.id:support.zoom.us"
    ws-opts:
      path: /vless
      headers:
        Host: neva.jhopanstore.my.id
    client-fingerprint: chrome
```

### Trojan + TLS

```yaml
proxies:
  - name: "trojan-onering"
    type: trojan
    server: support.zoom.us        # ← bug domain (CDN)
    port: 443
    password: PASSWORD
    sni: "onering:neva.jhopanstore.my.id:support.zoom.us"
    udp: true
```

### Hysteria2

```yaml
proxies:
  - name: "hy2-onering"
    type: hysteria2
    server: support.zoom.us        # ← bug domain (CDN)
    port: 443
    password: PASSWORD
    sni: "onering:neva.jhopanstore.my.id:support.zoom.us"
```

| Field | Isi | Keterangan |
|---|---|---|
| `server` | bug domain | TCP dial target |
| `servername` / `sni` | `onering:REAL:BUG` | format OneRing |
| WS `Host` | real domain | header WebSocket |

---

## 🚀 Deploy

### VPS / Server Linux

```bash
scp dist/mihomo.linux.amd64.onering root@SERVER:/usr/local/bin/mihomo
ssh root@SERVER 'chmod +x /usr/local/bin/mihomo && mihomo version'
```

### OpenWrt ARM64

```bash
scp dist/mihomo.linux.arm64.onering root@192.168.1.1:/tmp/mihomo
ssh root@192.168.1.1 '
  cp /usr/bin/mihomo /usr/bin/mihomo.bak
  mv /tmp/mihomo /usr/bin/mihomo && chmod +x /usr/bin/mihomo
  mihomo version
'
```

### OpenWrt ARMv7 (32-bit)

```bash
scp dist/mihomo.linux.armv7.onering root@ROUTER:/tmp/mihomo
# sama seperti arm64
```

### Windows

```bat
dist\mihomo.windows.amd64.onering.exe -d config_dir
```

---

## 🔄 Update ke Versi Baru

```bash
bash apply.sh --list
bash build.sh --force --ver v1.x.y all
bash verify.sh
```

**Jika patch conflict:**

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

---

## 🌐 Ekosistem OneRing

| Repo | Engine | Config key |
|---|---|---|
| [xray-onering](https://github.com/jhopan/xray-onering) | Xray-core | `serverName` |
| [singbox-onering](https://github.com/jhopan/singbox-onering) | sing-box | `server_name` |
| **[clash-onering](https://github.com/jhopan/clash-onering)** ← kamu di sini | Mihomo/Clash | `servername` / `sni` |

---

## 📜 Credits & Lisensi

| | |
|---|---|
| 👨‍💻 Developer kit | **JhopanStore** |
| 💡 Metode OneRing | [dharak36/xray-onering](https://github.com/dharak36/xray-onering) |
| ⚙️ Engine | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) — GPL-3.0 |

**Kit ini** (patch, script, docs): **MIT License** © JhopanStore  
**Binary hasil build**: mengandung Mihomo (GPL-3.0 upstream)
