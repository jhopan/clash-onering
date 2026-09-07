# SNI proof listener — capture ClientHello mentah dari mihomo onering
# Bukti packet-level: isi ClientHello memuat REAL domain, tanpa string "onering:"
import socket

EXPECT = b"neva.jhopanstore.my.id"

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", 18443))
srv.listen(1)
srv.settimeout(20)
print("listener up 127.0.0.1:18443, waiting ClientHello...", flush=True)
try:
    conn, addr = srv.accept()
    conn.settimeout(5)
    data = b""
    try:
        while len(data) < 16384:
            chunk = conn.recv(4096)
            if not chunk:
                break
            data += chunk
    except socket.timeout:
        pass
    conn.close()
    has_sni_real = EXPECT in data
    has_onering = b"onering:" in data
    print(f"captured {len(data)} bytes from {addr}")
    print(f"ClientHello contains REAL domain ({EXPECT.decode()}): {has_sni_real}")
    print(f"ClientHello contains raw 'onering:' string: {has_onering}")
    if has_sni_real and not has_onering:
        print("VERDICT: PASS — SNI on the wire = real domain, format onering: never leaves the core")
    else:
        print("VERDICT: FAIL")
except socket.timeout:
    print("VERDICT: FAIL — no connection received")
