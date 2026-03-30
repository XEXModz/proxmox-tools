# proxmox-tools
Simple scripts to manage your Proxmox firewall and open ports automatically.

---

## One Liner Install
Installs git if needed, removes any old proxmox-tools folder, clones fresh, and launches the menu:
```bash
apt-get install -y git && rm -rf proxmox-tools && git clone https://github.com/XEXModz/proxmox-tools.git && cd proxmox-tools && chmod +x *.sh && sudo ./run.sh
```

---

## Tools

### 🔥 reinstall-firewall.sh
Reinstalls and restarts the Proxmox firewall from scratch.
Use this if your firewall is broken, missing, or misbehaving.

```bash
sudo ./reinstall-firewall.sh
```

---

### 🔓 open-ports.sh
Scans all services currently listening on your server and asks you one by one whether to open each port in the Proxmox firewall. Shows the service name, port, and full IP address so you know exactly what you're opening.

```bash
sudo ./open-ports.sh
```

**Example:**
```
  ┌─────────────────────────────────────────
  │  Service : http
  │  Port    : 80
  │  Address : 192.168.1.50:80
  └─────────────────────────────────────────
  If you don't recognize this service, type n to reject it.
  Open this port? (y/n):
```

**Summary at the end:**
```
  Always Open (protected):
    Port 22   (SSH)         →  192.168.1.50:22
    Port 8006 (Proxmox UI)  →  192.168.1.50:8006

  Opened:
    ✓ Port 80  (http)   →  192.168.1.50:80
    ✓ Port 443 (https)  →  192.168.1.50:443

  Skipped:
    ✗ Port 3306 (mysql)
```

---

### 🚀 run.sh
Interactive menu to launch either tool.

```bash
sudo ./run.sh
```

```
==============================
   Proxmox Helper Toolkit
==============================

  1) Reinstall Firewall
  2) Detect + Open Ports
  0) Exit
```

---

## Notes
- All scripts must be run as root or with sudo — they will error and exit if not
- Port 22 (SSH) and 8006 (Proxmox Web UI) are always kept open automatically
- The two tools work independently — use whichever one you need
- Run open-ports.sh again any time you install a new service
