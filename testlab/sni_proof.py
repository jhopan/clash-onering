# SNI proof listener — capture ClientHello dari mihomo onering
# Bukti: SNI yang terkirim = REAL domain (bukan string onering:, bukan bug)
import socket, sys

EXPECT = b"neva.jhopanstore.my.id"

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", 8443))
srv.listen(1)
srv.settimeout(15)
print("listener up 127.0.0.1:8443, waiting ClientHello...", flush=True)
try:
    conn, addr = srv.accept()
    conn.settimeout(5)
    data = b""
    try:
        while len(data) < 8192:
            chunk = conn.recv(4096)
            if not chunk:
                break
            data += chunk
    except socket.timeout:
        pass
    conn.close()
    has_sni_real = EXPECT in data
    has_onering = b"onering:" in data
    has_bug_literal = b"127.0.0.1" in data
    print(f"captured {len(data)} bytes")
    print(f"SNI contains REAL ({EXPECT.decode()}): {has_sni_real}")
    print(f"contains raw 'onering:' string: {has_onering}")
    print("VERDICT: " + ("PASS — SNI overridden to real domain" if (has_sni_real and not has_onering) else "FAIL"))
except socket.timeout:
    print("VERDICT: FAIL — no connection received")
