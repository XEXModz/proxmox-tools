while true; do
    clear
    echo "=============================="
    echo "   Proxmox Helper Toolkit"
    echo "=============================="
    echo ""
    echo "1) Reinstall Firewall  (Did you break it again? 😂)"
    echo "2) Detect + Open Ports"
    echo "0) Exit"
    echo ""

    read -p "Choose an option: " choice

    case $choice in
        1)
            sudo bash reinstall-firewall.sh
            read -p "Press Enter to continue..."
            ;;
        2)
            sudo bash open-ports.sh
            read -p "Press Enter to continue..."
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
done
