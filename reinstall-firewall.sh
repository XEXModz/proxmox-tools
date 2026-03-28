#!/bin/bash
# Proxmox Firewall Reinstaller
# Reinstalls and restarts the Proxmox firewall from scratch

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

echo ""
echo "=============================="
echo "  Proxmox Firewall Reinstall"
echo "=============================="
echo ""

echo "[1/3] Updating package list..."
apt update -qq

echo "[2/3] Reinstalling pve-firewall..."
apt install --reinstall -y pve-firewall

echo "[3/3] Enabling and starting firewall..."
systemctl enable pve-firewall
systemctl start pve-firewall

echo ""
echo "=============================="
echo "  Done! Firewall is running."
echo "=============================="
echo ""
