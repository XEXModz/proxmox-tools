#!/bin/bash
# Proxmox Auto Port Opener with basic safety

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root or with sudo!"
    exit 1
fi

NODE_FW="/etc/pve/nodes/$(hostname)/host.fw"

if [[ ! -f "$NODE_FW" ]]; then
    echo "ERROR: host.fw not found at $NODE_FW"
    exit 1
fi

SERVER_IPS=$(hostname -I | tr ' ' '\n' | grep -v '^$')

if ! grep -q "^\[RULES\]" "$NODE_FW"; then
    echo "[RULES]" >> "$NODE_FW"
fi

for port in 22 8006; do
    if ! grep -q "IN ACCEPT -p tcp -dport $port" "$NODE_FW"; then
        echo "IN ACCEPT -p tcp -dport $port" >> "$NODE_FW"
    fi
done

echo ""
echo "Server IP Addresses:"
echo "----------------------------"
echo "$SERVER_IPS"
echo "----------------------------"
echo ""
echo "Opened Ports:"
echo "----------------------------"

ss -tlnp | awk '/LISTEN/ && !/127.0.0.1/' | while read -r line; do
    full=$(echo "$line" | awk '{print $4}')
    listen_ip=$(echo "$full" | rev | cut -d: -f2- | rev)
    port=$(echo "$full" | rev | cut -d: -f1 | rev)

    if ! grep -q "IN ACCEPT -p tcp -dport $port" "$NODE_FW"; then
        echo "IN ACCEPT -p tcp -dport $port" >> "$NODE_FW"
    fi

    if [[ "$listen_ip" == "0.0.0.0" || "$listen_ip" == "*" || "$listen_ip" == "::" ]]; then
        while read -r ip; do
            echo "  Port $port  →  $ip:$port"
        done <<< "$SERVER_IPS"
    else
        echo "  Port $port  →  $listen_ip:$port"
    fi
done

if ! pve-firewall restart; then
    echo "ERROR: Failed to restart pve-firewall!"
    exit 1
fi

echo ""
echo "Done! All listening ports are now open."
