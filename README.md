# proxmox-tools
Simple scripts to reinstall your Proxmox firewall and open ports automatically.

---

## Tools

### reinstall-firewall.sh
Reinstalls and restarts the Proxmox firewall from scratch. Use this if your firewall is broken or missing.

### open-ports.sh
Detects all services listening on your server and automatically opens those ports in the Proxmox firewall. Shows you every open port and the full IP address it is available on.

---

## One Liner Install (Recommended)

**Reinstall Firewall:** Copy and paste to reinstall the firewall.
```bash
curl -sSL https://raw.githubusercontent.com/XEXModz/proxmox-tools/main/reinstall-firewall.sh | sudo bash
```

**Open Ports:** Copy and paste to detect and open ports.
```bash
curl -sSL https://raw.githubusercontent.com/XEXModz/proxmox-tools/main/open-ports.sh | sudo bash
```

---

## Manual Install

```bash
git clone https://github.com/XEXModz/proxmox-tools
cd proxmox-tools
sudo chmod +x reinstall-firewall.sh open-ports.sh
```

**Reinstall Firewall:**
```bash
sudo ./reinstall-firewall.sh
```

**Open Ports:**
```bash
sudo ./open-ports.sh
```

---

## Example Output (open-ports.sh)

```
Server IP Addresses:
----------------------------
192.168.1.50
----------------------------

Opened Ports:
----------------------------
  Port 22    →  192.168.1.50:22
  Port 8006  →  192.168.1.50:8006
  Port 3000  →  192.168.1.50:3000
----------------------------
Done! All listening ports are now open.
```

---

## Notes
- Both tools work independently, use whichever one you need
- Must be run as root or with sudo
- Port 22 (SSH) and 8006 (Proxmox Web UI) are always kept open automatically
- Run open-ports.sh again any time you install a new service
