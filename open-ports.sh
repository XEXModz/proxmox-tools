#!/bin/bash
# Proxmox Auto Port Opener (Interactive Mode)
# Detects all listening ports and asks before opening them

# Root/sudo check
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root or with sudo!"
    echo "Try: sudo ./open-ports.sh"
    exit 1
fi

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
echo "Detected Ports (Interactive Mode):"
echo "----------------------------"
echo "Tip: If you don't recognize the service, type 'n' to stay safe."
echo ""

ss -tlnp | awk '/LISTEN/ && !/127.0.0.1/' | while read -r line; do
    full=$(echo "$line" | awk '{print $4}')
    listen_ip=$(echo "$full" | rev | cut -d: -f2- | rev)
    port=$(echo "$full" | rev | cut -d: -f1 | rev)

    # Extract service name (process)
    service=$(echo "$line" | awk -F'"' '{print $2}')
    [[ -z "$service" ]] && service="unknown"

    echo ""
    echo "Detected service: $service (port $port)"

    read -p "Allow this port? [y/N]: " choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        if ! grep -q "IN ACCEPT -p tcp -dport $port" "$NODE_FW"; then
            echo "IN ACCEPT -p tcp -dport $port" >> "$NODE_FW"
            echo "  → Allowed"
        else
            echo "  → Already allowed"
        fi

        # Display mapping
        if [[ "$listen_ip" == "0.0.0.0" || "$listen_ip" == "*" || "$listen_ip" == "::" ]]; then
            while read -r ip; do
                echo "  Port $port  →  $ip:$port"
            done <<< "$SERVER_IPS"
        else
            echo "  Port $port  →  $listen_ip:$port"
        fi
    else
        echo "  → Skipped"
    fi

done

echo "----------------------------"

pve-firewall restart

echo ""
echo "Done! Selected ports are now open."
