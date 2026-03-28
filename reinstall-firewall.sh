#!/bin/bash
# Proxmox Firewall Reinstaller
# Usage: sudo chmod +x reinstall-firewall.sh && sudo ./reinstall-firewall.sh

# Root/sudo check
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root or with sudo!"
    echo "Try: sudo ./reinstall-firewall.sh"
    exit 1
fi

echo "Updating package list..."
apt update

echo "Reinstalling pve-firewall..."
apt install --reinstall -y pve-firewall

echo "Enabling and starting firewall..."
systemctl enable pve-firewall
systemctl start pve-firewall

echo ""
echo "Done! Firewall reinstalled and running."
