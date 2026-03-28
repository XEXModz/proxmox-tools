#!/bin/bash
# Proxmox Firewall Reinstaller
# Usage: sudo chmod +x reinstall-firewall.sh && sudo ./reinstall-firewall.sh

echo "Updating package list..."
apt update

echo "Reinstalling pve-firewall..."
apt install --reinstall -y pve-firewall

echo "Enabling and starting firewall..."
systemctl enable pve-firewall
systemctl start pve-firewall

echo ""
echo "Done! Firewall reinstalled and running."
