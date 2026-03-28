#!/bin/bash
# Proxmox Tools Launcher
# One script to run everything

# Root check
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "  ERROR: This script must be run as root or with sudo!"
    echo "  Try: sudo ./run.sh"
    echo ""
    exit 1
fi

clear

echo ""
echo "=============================="
echo "   Proxmox Helper Toolkit"
echo "=============================="
echo ""
echo "  1) Reinstall Firewall"
echo "  2) Detect + Open Ports"
echo "  0) Exit"
echo ""
read -rp "  Choose an option: " choice
echo ""

case $choice in
    1)
        bash "$(dirname "$0")/reinstall-firewall.sh"
        ;;
    2)
        bash "$(dirname "$0")/open-ports.sh"
        ;;
    0)
        echo "  Bye!"
        echo ""
        exit 0
        ;;
    *)
        echo "  Invalid option. Run ./run.sh and try again."
        echo ""
        exit 1
        ;;
esac
