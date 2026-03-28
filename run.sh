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

# Get the real directory this script lives in — always reliable
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-install git if missing
if ! command -v git &> /dev/null; then
    echo ""
    echo "  Git not found, installing..."
    apt-get update -qq && apt-get install -y git
    echo "  Git installed!"
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
        LAUNCHED_BY_RUNNER=1 bash "$SCRIPT_DIR/reinstall-firewall.sh"
        ;;
    2)
        LAUNCHED_BY_RUNNER=1 bash "$SCRIPT_DIR/open-ports.sh"
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
