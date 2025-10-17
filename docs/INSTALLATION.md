# Installation Guide

This guide provides detailed step-by-step instructions for installing and configuring the Universal SIP WebSocket Proxy on Ubuntu 22.04 or 24.04.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [System Preparation](#system-preparation)
3. [Automated Installation](#automated-installation)
4. [Manual Installation](#manual-installation)
5. [Configuration](#configuration)
6. [SSL Certificate Setup](#ssl-certificate-setup)
7. [Starting Services](#starting-services)
8. [Verification](#verification)
9. [Post-Installation](#post-installation)

## Prerequisites

### Hardware Requirements

- **Minimum**:
  - 2 CPU cores
  - 2 GB RAM
  - 20 GB disk space
  - Network interface with public IP

- **Recommended**:
  - 4+ CPU cores
  - 4+ GB RAM
  - 50+ GB SSD storage
  - Dedicated network interface

### Software Requirements

- Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- Root or sudo access
- Domain name with DNS configured
- Open ports (see Network Requirements below)

### Network Requirements

The following ports must be accessible from the internet:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH (for management) |
| 80 | TCP | HTTP (Let's Encrypt validation) |
| 443 | TCP | HTTPS/WSS (WebSocket Secure) |
| 8080 | TCP | WebSocket (optional, non-secure) |
| 5060 | UDP/TCP | SIP signaling |
| 5061 | TCP | SIP over TLS |
| 10000-20000 | UDP | RTP/RTCP media |

### DNS Configuration

Before installation, ensure your domain is properly configured:

```bash
# Your domain should resolve to your server's IP
dig sipproxy.yourdomain.com +short
# Should return: YOUR_SERVER_IP
```

## System Preparation

### 1. Update System

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### 2. Set Hostname (Optional)

```bash
sudo hostnamectl set-hostname sipproxy.yourdomain.com
```

### 3. Configure Timezone

```bash
sudo timedatectl set-timezone America/New_York  # Or your timezone
```

### 4. Install Basic Tools

```bash
sudo apt-get install -y git curl wget vim net-tools
```

## Automated Installation

The easiest way to install is using the provided installation script.

### 1. Clone Repository

```bash
cd /opt
sudo git clone https://github.com/jishanalibd/universal-sip-websocket-proxy.git
cd universal-sip-websocket-proxy
```

### 2. Run Installation Script

```bash
sudo bash scripts/install.sh
```

This script will:
- Install all required packages
- Set up Kamailio and rtpengine
- Configure firewall rules
- Install systemd service files
- Detect and configure network interfaces

The installation takes approximately 5-10 minutes.

### 3. Configure Domain

Edit the Kamailio configuration:

```bash
sudo vim /etc/kamailio/kamailio.cfg
```

Find and update the DOMAIN definition:

```
#!define DOMAIN "sipproxy.yourdomain.com"
```

### 4. Set Up SSL Certificates

```bash
sudo bash scripts/setup-ssl.sh sipproxy.yourdomain.com admin@yourdomain.com
```

### 5. Start Services

```bash
sudo systemctl start ngcp-rtpengine-daemon
sudo systemctl start kamailio
```

### 6. Verify Services

```bash
sudo systemctl status ngcp-rtpengine-daemon
sudo systemctl status kamailio
```

That's it! Skip to the [Verification](#verification) section.

## Manual Installation

If you prefer manual installation or need more control:

### 1. Install Kamailio

#### Add Repository

For Ubuntu 22.04:
```bash
wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/kamailio-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kamailio-archive-keyring.gpg] http://deb.kamailio.org/kamailio58 jammy main" | sudo tee /etc/apt/sources.list.d/kamailio.list
```

For Ubuntu 24.04:
```bash
wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/kamailio-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kamailio-archive-keyring.gpg] http://deb.kamailio.org/kamailio58 noble main" | sudo tee /etc/apt/sources.list.d/kamailio.list
```

#### Install Packages

```bash
sudo apt-get update
sudo apt-get install -y \
    kamailio \
    kamailio-websocket-modules \
    kamailio-tls-modules \
    kamailio-json-modules \
    kamailio-utils-modules \
    kamailio-extra-modules
```

### 2. Install rtpengine

#### Add Repository

```bash
wget -O- https://dfx.at/sipwise-signing-key.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/sipwise-archive-keyring.gpg
```

For Ubuntu 22.04:
```bash
echo "deb [signed-by=/usr/share/keyrings/sipwise-archive-keyring.gpg] https://deb.sipwise.com/spce/mr11.5 jammy main" | sudo tee /etc/apt/sources.list.d/sipwise.list
```

For Ubuntu 24.04:
```bash
echo "deb [signed-by=/usr/share/keyrings/sipwise-archive-keyring.gpg] https://deb.sipwise.com/spce/mr11.5 noble main" | sudo tee /etc/apt/sources.list.d/sipwise.list
```

#### Install Packages

```bash
sudo apt-get update
sudo apt-get install -y \
    ngcp-rtpengine-daemon \
    ngcp-rtpengine-kernel-dkms \
    ngcp-rtpengine-utils
```

#### Load Kernel Module

```bash
sudo modprobe xt_RTPENGINE
echo "xt_RTPENGINE" | sudo tee /etc/modules-load.d/rtpengine.conf
```

### 3. Configure Kamailio

```bash
# Backup original config
sudo cp /etc/kamailio/kamailio.cfg /etc/kamailio/kamailio.cfg.original

# Copy our config
sudo cp config/kamailio/kamailio.cfg /etc/kamailio/kamailio.cfg
sudo cp config/kamailio/tls.cfg /etc/kamailio/tls.cfg

# Set permissions
sudo chown kamailio:kamailio /etc/kamailio/kamailio.cfg
sudo chmod 644 /etc/kamailio/kamailio.cfg
```

Edit and configure:

```bash
sudo vim /etc/kamailio/kamailio.cfg
```

Update the domain:
```
#!define DOMAIN "sipproxy.yourdomain.com"
```

### 4. Configure rtpengine

```bash
# Backup original config
sudo cp /etc/rtpengine/rtpengine.conf /etc/rtpengine/rtpengine.conf.original

# Copy our config
sudo cp config/rtpengine/rtpengine.conf /etc/rtpengine/rtpengine.conf
```

Edit configuration:

```bash
sudo vim /etc/rtpengine/rtpengine.conf
```

Update interface configuration:
```
interface = PRIVATE_IP!PUBLIC_IP
```

Replace PRIVATE_IP and PUBLIC_IP with your actual IPs:

```bash
# Get private IP
PRIVATE_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)

# Get public IP
PUBLIC_IP=$(curl -s https://api.ipify.org)

# Update config
sudo sed -i "s/PRIVATE_IP/${PRIVATE_IP}/g" /etc/rtpengine/rtpengine.conf
sudo sed -i "s/PUBLIC_IP/${PUBLIC_IP}/g" /etc/rtpengine/rtpengine.conf
```

### 5. Configure Firewall

```bash
sudo bash scripts/firewall.sh
```

Or manually:

```bash
sudo ufw --force enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS/WSS
sudo ufw allow 8080/tcp  # WebSocket
sudo ufw allow 5060/udp  # SIP UDP
sudo ufw allow 5060/tcp  # SIP TCP
sudo ufw allow 5061/tcp  # SIP TLS
sudo ufw allow 10000:20000/udp  # RTP
sudo ufw reload
```

## SSL Certificate Setup

### Using Let's Encrypt (Recommended)

```bash
sudo bash scripts/setup-ssl.sh sipproxy.yourdomain.com admin@yourdomain.com
```

### Manual Certificate Setup

If you have your own certificates:

```bash
# Copy certificates
sudo cp your-cert.pem /etc/kamailio/cert.pem
sudo cp your-key.pem /etc/kamailio/key.pem

# Update tls.cfg
sudo vim /etc/kamailio/tls.cfg
```

Update paths in tls.cfg:
```
private_key = /etc/kamailio/key.pem
certificate = /etc/kamailio/cert.pem
```

## Starting Services

### Enable Services

```bash
sudo systemctl enable ngcp-rtpengine-daemon
sudo systemctl enable kamailio
```

### Start Services

```bash
# Start rtpengine first
sudo systemctl start ngcp-rtpengine-daemon

# Then start Kamailio
sudo systemctl start kamailio
```

### Check Status

```bash
sudo systemctl status ngcp-rtpengine-daemon
sudo systemctl status kamailio
```

## Verification

### 1. Check Service Logs

**Kamailio logs:**
```bash
sudo tail -f /var/log/syslog | grep kamailio
```

**rtpengine logs:**
```bash
sudo journalctl -u ngcp-rtpengine-daemon -f
```

### 2. Test WebSocket Connection

Install wscat:
```bash
sudo npm install -g wscat
```

Test connection:
```bash
wscat -c wss://sipproxy.yourdomain.com:443
```

You should see a WebSocket connection established.

### 3. Test SIP Registration

Use a SIP client (like Linphone or Zoiper) to test:

- **WebSocket URI**: `wss://sipproxy.yourdomain.com:443`
- **Username**: Your SIP username
- **Password**: Your SIP password
- **Domain**: Your actual SIP server domain

### 4. Monitor rtpengine

```bash
rtpengine-ctl list
```

### 5. Check Listening Ports

```bash
sudo netstat -tulpn | grep -E "kamailio|rtpengine"
```

Expected output should show:
- Port 443 (Kamailio - WSS)
- Port 5060 (Kamailio - SIP UDP/TCP)
- Port 2223 (rtpengine control)
- Ports 10000-20000 (rtpengine RTP)

## Post-Installation

### 1. Configure Monitoring

Set up log rotation:

```bash
sudo vim /etc/logrotate.d/kamailio
```

Add:
```
/var/log/kamailio/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 kamailio kamailio
}
```

### 2. Performance Tuning

Edit `/etc/kamailio/kamailio.cfg` and adjust:

```
# Increase shared memory
shm_mem=256
```

For rtpengine, edit `/etc/rtpengine/rtpengine.conf`:

```
num-threads = 8  # Set to number of CPU cores
```

### 3. Security Hardening

- Enable fail2ban for brute-force protection
- Implement rate limiting in Kamailio
- Use IP whitelisting if possible
- Regular security updates

### 4. Backup Configuration

```bash
sudo mkdir -p /root/backups
sudo tar -czf /root/backups/sip-proxy-config-$(date +%Y%m%d).tar.gz \
    /etc/kamailio \
    /etc/rtpengine
```

### 5. Set Up Monitoring

Consider installing:
- Prometheus + Grafana for metrics
- Homer for SIP capture and troubleshooting
- Nagios/Zabbix for service monitoring

## Troubleshooting

If you encounter issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common problems and solutions.

## Next Steps

- [Configure your web client](CLIENT-EXAMPLES.md)
- Set up monitoring and alerting
- Configure database backend for user management
- Implement authentication and authorization
- Set up high availability (if needed)

## Support

For issues and questions:
- Check the logs: `/var/log/syslog` (Kamailio) and `journalctl -u ngcp-rtpengine-daemon` (rtpengine)
- Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Create an issue on GitHub
