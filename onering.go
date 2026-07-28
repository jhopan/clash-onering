package vmess

import "strings"

// ParseOneRing parses OneRing format: onering:real:bug
// Returns (real, bug) or ("", "") if not OneRing format.
// real = domain for TLS SNI, bug = domain for TCP connection (server field).
func ParseOneRing(serverName string) (real, bug string) {
	const prefix = "onering:"
	if !strings.HasPrefix(strings.ToLower(serverName), prefix) {
		return "", ""
	}
	parts := strings.SplitN(serverName, ":", 3)
	if len(parts) != 3 || parts[1] == "" || parts[2] == "" {
		return "", ""
	}
	return strings.TrimSpace(parts[1]), strings.TrimSpace(parts[2])
}
