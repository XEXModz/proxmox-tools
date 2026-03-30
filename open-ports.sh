#!/bin/bash
# Proxmox Auto Port Opener
# Detects all listening ports and asks before opening each one

# Root check
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "  ERROR: This script must be run as root or with sudo!"
    echo "  Try: sudo ./run.sh"
    echo ""
    exit 1
fi

# Block direct execution - must be run via run.sh
if [[ "${BASH_SOURCE[0]}" == "${0}" && "$LAUNCHED_BY_RUNNER" != "1" ]]; then
    echo ""
    echo "  ERROR: Don't run this script directly!"
    echo "  Use the one liner to launch the toolkit:"
    echo ""
    echo "  apt-get install -y git && if [ -d \"proxmox-tools\" ]; then cd proxmox-tools && git pull; else git clone https://github.com/XEXModz/proxmox-tools.git && cd proxmox-tools; fi && chmod +x *.sh && sudo ./run.sh"
    echo ""
    exit 1
fi

NODE_FW="/etc/pve/nodes/$(hostname)/host.fw"

# Check firewall config exists
if [[ ! -f "$NODE_FW" ]]; then
    echo ""
    echo "  ERROR: Proxmox firewall config not found at $NODE_FW"
    echo "  Run reinstall-firewall.sh first!"
    echo ""
    exit 1
fi

# Get the server's local IP addresses
SERVER_IPS=$(hostname -I | tr ' ' '\n' | grep -v '^$')

# Ensure [RULES] section exists
if ! grep -q "^\[RULES\]" "$NODE_FW"; then
    echo "[RULES]" >> "$NODE_FW"
fi

echo ""
echo "=============================="
echo "   Proxmox Auto Port Opener"
echo "=============================="
echo ""
echo "Server IP Addresses:"
echo "------------------------------"
echo "$SERVER_IPS"
echo "------------------------------"
echo ""
echo "Scanning listening ports..."
echo ""

OPENED=()
SKIPPED=()
WARNED=()

# Known risky ports - port:reason
declare -A RISKY_PORTS
RISKY_PORTS=(
    [21]="FTP — sends passwords in plain text, use SFTP instead"
    [23]="Telnet — completely unencrypted, use SSH instead"
    [25]="SMTP — open mail relay, can be abused to send spam"
    [53]="DNS — exposing this publicly can enable DNS amplification attacks"
    [137]="NetBIOS — Windows file sharing, should never be public"
    [138]="NetBIOS — Windows file sharing, should never be public"
    [139]="NetBIOS — Windows file sharing, should never be public"
    [445]="SMB — Windows file sharing, extremely dangerous to expose publicly"
    [512]="rexec — remote execution with no encryption"
    [513]="rlogin — unencrypted remote login"
    [514]="rsh — remote shell with no encryption or authentication"
    [1433]="MSSQL — database port, should never be publicly exposed"
    [1521]="Oracle DB — database port, should never be publicly exposed"
    [2375]="Docker — unencrypted Docker API, full server takeover risk"
    [2376]="Docker — Docker API, only expose if you know what you are doing"
    [3306]="MySQL — database port, should never be publicly exposed"
    [3389]="RDP — Windows remote desktop, high brute-force attack target"
    [5432]="PostgreSQL — database port, should never be publicly exposed"
    [5900]="VNC — remote desktop, often has weak auth and no encryption"
    [5984]="CouchDB — database port, should never be publicly exposed"
    [6379]="Redis — no auth by default, full data exposure risk"
    [7001]="WebLogic — known RCE vulnerabilities, high risk"
    [8080]="HTTP Alternate — make sure this is intentional before opening"
    [8443]="HTTPS Alternate — make sure this is intentional before opening"
    [9200]="Elasticsearch — no auth by default, full data exposure risk"
    [9300]="Elasticsearch — no auth by default, full data exposure risk"
    [11211]="Memcached — no auth by default, used in DDoS amplification attacks"
    [27017]="MongoDB — no auth by default, full data exposure risk"
    [27018]="MongoDB — no auth by default, full data exposure risk"
)

# Always silently ensure SSH and Proxmox UI are open
for port in 22 8006; do
    if ! grep -q "IN ACCEPT -p tcp -dport $port" "$NODE_FW"; then
        echo "IN ACCEPT -p tcp -dport $port" >> "$NODE_FW"
    fi
done

# Loop through all listening TCP ports
while IFS= read -r line; do
    full=$(echo "$line" | awk '{print $4}')
    listen_ip=$(echo "$full" | rev | cut -d: -f2- | rev)
    port=$(echo "$full" | rev | cut -d: -f1 | rev)

    # Skip empty or invalid ports
    [[ -z "$port" || ! "$port" =~ ^[0-9]+$ ]] && continue

    # Skip SSH and Proxmox UI (already handled)
    [[ "$port" == "22" || "$port" == "8006" ]] && continue

    # Try to get a friendly service name
    service=$(grep -w "${port}/tcp" /etc/services 2>/dev/null | head -1 | awk '{print $1}')
    process=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+' 2>/dev/null)
    [[ -z "$service" && -n "$process" ]] && service="$process"
    [[ -z "$service" ]] && service="unknown"

    # Build display IP
    if [[ "$listen_ip" == "0.0.0.0" || "$listen_ip" == "*" || "$listen_ip" == "::" ]]; then
        display_ip=$(echo "$SERVER_IPS" | head -1)
    else
        display_ip="$listen_ip"
    fi

    # Check if this is a risky port
    IS_RISKY=0
    RISK_REASON=""
    if [[ -n "${RISKY_PORTS[$port]+_}" ]]; then
        IS_RISKY=1
        RISK_REASON="${RISKY_PORTS[$port]}"
    fi

    echo "  ┌─────────────────────────────────────────"
    echo "  │  Service : $service"
    echo "  │  Port    : $port"
    echo "  │  Address : $display_ip:$port"
    if [[ $IS_RISKY -eq 1 ]]; then
        echo "  │"
        echo "  │  ⚠ WARNING: $RISK_REASON"
    fi
    echo "  └─────────────────────────────────────────"

    if [[ $IS_RISKY -eq 1 ]]; then
        echo "  ⚠ This port is flagged as risky. Only open it if you are 100% sure you need it."
        echo "  🚫 NEVER port forward this port on your router — doing so exposes it to the entire internet."
        echo ""
        read -rp "  Type exactly  y --confirm  to open this risky port, or n to skip: " answer < /dev/tty
        echo ""
        if [[ "$answer" == "y --confirm" ]]; then
            if ! grep -q "IN ACCEPT -p tcp -dport $port" "$NODE_FW"; then
                echo "IN ACCEPT -p tcp -dport $port" >> "$NODE_FW"
            fi
            OPENED+=("⚠ Port $port ($service)  →  $display_ip:$port  [RISKY]")
            WARNED+=("Port $port — $RISK_REASON")
        else
            SKIPPED+=("Port $port ($service)  [risky - skipped]")
        fi
    else
        echo "  If you don't recognize this service, type n to reject it."
        read -rp "  Open this port? (y/n): " answer < /dev/tty
        echo ""
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            if ! grep -q "IN ACCEPT -p tcp -dport $port" "$NODE_FW"; then
                echo "IN ACCEPT -p tcp -dport $port" >> "$NODE_FW"
            fi
            OPENED+=("Port $port ($service)  →  $display_ip:$port")
        else
            SKIPPED+=("Port $port ($service)")
        fi
    fi

done < <(ss -tlnp | awk '/LISTEN/ && !/127.0.0.1/')

# Restart firewall to apply changes
pve-firewall restart > /dev/null 2>&1

# Summary
echo ""
echo "=============================="
echo "         Summary"
echo "=============================="
echo ""
echo "  Always Open (protected):"
echo "    Port 22   (SSH)          →  $(echo "$SERVER_IPS" | head -1):22"
echo "    Port 8006 (Proxmox UI)   →  $(echo "$SERVER_IPS" | head -1):8006"
echo ""

if [[ ${#OPENED[@]} -gt 0 ]]; then
    echo "  Opened:"
    for entry in "${OPENED[@]}"; do
        echo "    ✓ $entry"
    done
    echo ""
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo "  Skipped:"
    for entry in "${SKIPPED[@]}"; do
        echo "    ✗ $entry"
    done
    echo ""
fi

if [[ ${#WARNED[@]} -gt 0 ]]; then
    echo "  ⚠ Risky ports you opened — keep an eye on these:"
    for entry in "${WARNED[@]}"; do
        echo "    ! $entry"
    done
    echo ""
fi

echo "=============================="
echo "  Done! Firewall rules saved."
echo "=============================="
echo ""
