## 🛠 Advanced WireGuard & Network Management Cheatsheet

### 0. Installation (Standard Setup)

Before configuring, ensure the necessary tools are installed on your Manjaro system:

```bash
# Update package database and install WireGuard tools
sudo pacman -Syu wireguard-tools
```

### 1. Security & Firewall (UFW)

```bash
# Open your central rules file
fwe

# Locate the VPN Configuration section and fill in your endpoint:
# vpn_interface wg0
# vpn_endpoint <VPN_ENDPOINT_IP>
# vpn_port 51820

# Apply changes and rebuild the entire UFW stack
fwr
```

### 2. WireGuard Configuration (`/etc/wireguard/wg0.conf`)

Optimize your ProtonVPN config(`.conf`) to prevent local network lockout and ensure a resilient connection.

```ini
[Interface]
PrivateKey = <YOUR_PRIVATE_KEY>
Address = <ADDRESS>
DNS = <DNS_ADDRESS>

# Allow local network traffic to bypass the tunnel (Prevents lockout from router/local services)
# Replace 192.168.1.0/24 with your actual local subnet if different
PostUp = ip route add 192.168.1.0/24 dev wlp3s0 proto static scope link
# Selective Kill-Switch: Allow traffic to VPN Endpoint to ensure handshake can re-establish
PostUp = iptables -I OUTPUT -d <VPN_ENDPOINT_IP> -j ACCEPT
# General Kill-Switch: Block all other non-VPN outbound traffic
PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT

# Clean up rules when the interface is brought down
PreDown = ip route del 192.168.1.0/24 dev wlp3s0
PreDown = iptables -D OUTPUT -d <VPN_ENDPOINT_IP> -j ACCEPT
PreDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <VPN_ENDPOINT_IP>:51820
AllowedIPs = 0.0.0.0/0
```

---

### 3. Troubleshooting: `NO-CARRIER` Recovery Protocol

If your Wi-Fi reports `NO-CARRIER`, the physical link is dead. Follow this order to reset the stack correctly:

```bash
# 1. Stop the tunnel first to release hooks
sudo wg-quick down wg0

# 2. Reset the driver stack (Order is critical due to module dependencies)
# 'iwlmvm' depends on 'iwlwifi', so we remove the top layer first
sudo modprobe -r iwlmvm
sudo modprobe -r iwlwifi

# 3. Re-insert the drivers
sudo modprobe iwlwifi
sudo modprobe iwlmvm

# 4. Bring the physical interface up
sudo rfkill unblock wifi
sudo ip link set wlp3s0 up

# 5. Verify L1/L2 link (Wait until NO-CARRIER is gone)
ip addr show wlp3s0

# 6. Re-establish the tunnel
sudo wg-quick up wg0
```

---

### 4. Common Errors & Solutions

#### A. Module "In Use" Error

If `modprobe -r` fails, it's because the module is still being utilized by the kernel or a process.

- **Fix:** Ensure the interface is down (`sudo ip link set wlp3s0 down`) and no networking service is actively using it before removal.

#### B. DNS Resolution Failure

If you have internet but cannot resolve hostnames:

```bash
# Force create the symbolic link if it's a physical file
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
# Ensure systemd-resolved is managing DNS dynamically
sudo systemctl enable --now systemd-resolved
```

#### C. MTU Issues (Fragmentation - Slow Web Loading)

```ini
# Add this under [Interface] section in wg0.conf
# Lowering MTU prevents packet fragmentation over cellular or unstable Wi-Fi
MTU = 1280
```

#### D. IP Collision (Local vs VPN)

If an IP address within the VPN conflicts with an IP address on a device on your local network:

```bash
# Check existing routes to find conflicts
ip route show
# If needed, specify a more restrictive local route
# Example: only bypass the Gateway IP instead of the whole subnet
# PostUp = ip route add 192.168.1.1 dev wlp3s0
```

---

### 4. Summary of Commands

| Action                   | Command                     |
| :----------------------- | :-------------------------- |
| **🔒 VPN Start/Stop**    | `sudo wg-quick up/down wg0` |
| **📊 Check VPN Stats**   | `sudo wg show`              |
| **🔗 Firewall Menu**     | `fw`                        |
| **🔍 Firewall Status**   | `fws`                       |
| **🔄 Firewall Reload**   | `fwr`                       |
| **⚙ Check Service**      | `sst <service_name>`        |
| **: Interactive Status** | `sstat`                     |

**Engineering Tip:** `NO-CARRIER` durumunda interneti `wlp3s0`'a çekmek demek, VPN'i bypass etmek değildir. Bu işlem, VPN'in (L3) üzerinde koştuğu fiziksel hattın (L1) tamir edilmesidir. Yukarıdaki `PostUp` istisnası sayesinde, hattın tamiri biter bitmez VPN sızıntı yapmadan (Kill-Switch devredeyken) sunucuya bağlanacaktır.
