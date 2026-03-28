#!/bin/bash
# Proxmox Auto Port Opener
# Detects all listening ports and opens them in the Proxmox firewall
# Usage: sudo chmod +x open-ports.sh && sudo ./open-ports.sh

NODE_FW="/etc/pve/nodes/$(hostname)/host.fw"

# Get the server's actual local IP addresses
SERVER_IPS=$(hostname -I | tr ' ' '\n' | grep -v '^$')

# Ensure [RULES] section exists
if ! grep -q "^\[RULES\]" "$NODE_FW"; then
    echo "[RULES]" >> "$NODE_FW"
fi

# Always ensure SSH and Proxmox web UI are allowed
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

    # If listening on all interfaces, show all server IPs
    if [[ "$listen_ip" == "0.0.0.0" || "$listen_ip" == "*" || "$listen_ip" == "::" ]]; then
        while read -r ip; do
            echo "  Port $port  →  $ip:$port"
        done <<< "$SERVER_IPS"
    else
        echo "  Port $port  →  $listen_ip:$port"
    fi
done

echo "----------------------------"

pve-firewall restart

echo ""
echo "Done! All listening ports are now open."
