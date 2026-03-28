 #!/bin/bash
 # Proxmox Auto Port Opener (Interactive Mode)

  set -euo pipefail  # Catch errors early

  if [[ $EUID -ne 0 ]]; then
      echo "ERROR: Run as root or with sudo!"
      exit 1
  fi

  NODE_FW="/etc/pve/nodes/$(hostname)/host.fw"

  # Ensure [RULES] exists
  [[ -z "$(grep -c '^\[RULES\]' "$NODE_FW")" ]] && echo "[RULES]" >> "$NODE_FW"

  # Always allow SSH and Proxmox web UI
  for port in 22 8006; do
      ! grep -q "IN ACCEPT -p tcp -dport ${port}" "$NODE_FW" && \
          echo "IN ACCEPT -p tcp -dport ${port}" >> "$NODE_FW"
  done

  echo "Server IP Addresses:"
  hostname -I | tr ' ' '\n' | grep -v '^$'

  echo "Detected Ports:"
  ss -tlnp 2>/dev/null | awk '
      /LISTEN|STATE/ {
          split($4, a, ":")
          if (a[1] != "*" && a[1] != "::") next
          port = a[length(a)]
          service = $0
          gsub(/LISTEN|STATE/, "", service)
          print service " (" port ")"
      }' | while IFS= read -r line; do
      echo ""
      echo "$line"
      read -p "Allow? [y/N]: " choice

      case "$choice" in
          Y|y)
              ! grep -q "IN ACCEPT -p tcp -dport ${port}" "$NODE_FW" && \
                  echo "IN ACCEPT -p tcp -dport ${port}" >> "$NODE_FW" && \
                  echo "  → Allowed"
              ;;
          *) echo "  → Skipped" ;;
      esac
  done

  [[ -n "$(echo "$choice" | grep -iY)" ]] && \
      echo "IN ACCEPT -p tcp -dport ${port}" >> "$NODE_FW"

  echo ""
  echo "Restarting firewall..."
  if ! pve-firewall restart 2>&1; then
      echo "ERROR: pve-firewall restart failed!"
      exit 1
  fi

  echo "Done!"
