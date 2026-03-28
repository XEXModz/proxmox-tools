#!/bin/bash
# Proxmox Auto Port Opener
# Detects all listening ports and asks before opening each one

# Root check
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "  ERROR: This script must be run as root or with sudo!"
    echo "  Try: sudo ./open-ports.sh"
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

    echo "  ┌─────────────────────────────────────────"
    echo "  │  Service : $service"
    echo "  │  Port    : $port"
    echo "  │  Address : $display_ip:$port"
    echo "  └─────────────────────────────────────────"
    echo "  If you don't recognize this service, type n to reject it."
    read -rp "  Open this port? (y/n): " answer
    echo ""

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if ! grep -q "IN ACCEPT -p tcp -dport $port" "$NODE_FW"; then
            echo "IN ACCEPT -p tcp -dport $port" >> "$NODE_FW"
        fi
        OPENED+=("Port $port ($service)  →  $display_ip:$port")
    else
        SKIPPED+=("Port $port ($service)")
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

echo "=============================="
echo "  Done! Firewall rules saved."
echo "=============================="
echo ""
