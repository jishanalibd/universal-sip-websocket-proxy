# Troubleshooting Guide

This guide helps you diagnose and fix common issues with the Universal SIP WebSocket Proxy.

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Service Issues](#service-issues)
3. [WebSocket Connection Issues](#websocket-connection-issues)
4. [SIP Registration Issues](#sip-registration-issues)
5. [Audio/Media Issues](#audiomedia-issues)
6. [SSL/TLS Issues](#ssltls-issues)
7. [Performance Issues](#performance-issues)
8. [Logging and Debugging](#logging-and-debugging)

## Quick Diagnostics

Run these commands first to get an overview of system status:

```bash
# Check service status
sudo systemctl status kamailio
sudo systemctl status ngcp-rtpengine-daemon

# Check listening ports
sudo netstat -tulpn | grep -E "kamailio|rtpengine"

# Check recent logs
sudo tail -100 /var/log/syslog | grep kamailio
sudo journalctl -u ngcp-rtpengine-daemon -n 100

# Test WebSocket
wscat -c wss://sipproxy.yourdomain.com:443

# Check SSL certificate
openssl s_client -connect sipproxy.yourdomain.com:443 -servername sipproxy.yourdomain.com
```

## Service Issues

### Kamailio Won't Start

**Symptom:** `systemctl start kamailio` fails

**Check logs:**
```bash
sudo journalctl -xe -u kamailio
sudo tail -50 /var/log/syslog | grep kamailio
```

**Common causes:**

1. **Configuration syntax error:**
```bash
# Test configuration
sudo kamailio -c
```

2. **Port already in use:**
```bash
sudo netstat -tulpn | grep :443
sudo netstat -tulpn | grep :5060
```

Solution: Stop conflicting service or change Kamailio ports

3. **SSL certificate missing:**
```bash
ls -l /etc/letsencrypt/live/sipproxy.yourdomain.com/
```

Solution: Run `sudo bash scripts/setup-ssl.sh`

4. **Permissions issue:**
```bash
sudo chown -R kamailio:kamailio /var/run/kamailio
sudo chmod 755 /var/run/kamailio
```

### rtpengine Won't Start

**Symptom:** `systemctl start ngcp-rtpengine-daemon` fails

**Check logs:**
```bash
sudo journalctl -xe -u ngcp-rtpengine-daemon
```

**Common causes:**

1. **Kernel module not loaded:**
```bash
sudo lsmod | grep RTPENGINE
```

Solution:
```bash
sudo modprobe xt_RTPENGINE
```

2. **Configuration error:**
```bash
sudo rtpengine --config-file=/etc/rtpengine/rtpengine.conf --foreground
```

3. **Port conflict:**
```bash
sudo netstat -tulpn | grep :2223
```

Solution: Change port in `/etc/rtpengine/rtpengine.conf`

4. **Invalid interface configuration:**

Check and fix interface in `/etc/rtpengine/rtpengine.conf`:
```bash
# Get correct IPs
ip addr show
curl https://api.ipify.org

# Update config
sudo vim /etc/rtpengine/rtpengine.conf
# interface = PRIVATE_IP!PUBLIC_IP
```

### Service Crashes Repeatedly

**Check system resources:**
```bash
# Memory usage
free -h

# Disk space
df -h

# CPU usage
top -b -n 1 | head -20

# Check for OOM killer
sudo dmesg | grep -i "out of memory"
```

**Check for core dumps:**
```bash
sudo coredumpctl list
sudo coredumpctl info kamailio
```

## WebSocket Connection Issues

### Cannot Connect to WebSocket

**Test connection:**
```bash
wscat -c wss://sipproxy.yourdomain.com:443
```

**If connection fails:**

1. **Check firewall:**
```bash
sudo ufw status
sudo iptables -L -n | grep 443
```

2. **Check if Kamailio is listening:**
```bash
sudo netstat -tulpn | grep :443
```

3. **Test with HTTP:**
```bash
curl -I https://sipproxy.yourdomain.com
```

4. **Check DNS resolution:**
```bash
nslookup sipproxy.yourdomain.com
dig sipproxy.yourdomain.com
```

5. **Verify SSL certificate:**
```bash
openssl s_client -connect sipproxy.yourdomain.com:443 -servername sipproxy.yourdomain.com
```

### WebSocket Connects but Immediately Disconnects

**Check Kamailio logs:**
```bash
sudo tail -f /var/log/syslog | grep kamailio
```

**Common issues:**

1. **Origin header validation:**

In `/etc/kamailio/kamailio.cfg`, check the `xhttp:request` route:
```
# Temporarily disable origin check for testing
# if ($hdr(Origin) != "https://phone.yourdomain.com") {
#     xhttp_reply("403", "Forbidden", "", "");
#     exit;
# }
```

2. **WebSocket timeout:**

Increase timeout in `/etc/kamailio/kamailio.cfg`:
```
modparam("websocket", "keepalive_timeout", 60)
```

3. **NAT/Load balancer timeout:**

Configure proper keepalive intervals:
```
modparam("websocket", "keepalive_interval", 10)
modparam("websocket", "ping_interval", 30)
```

## SIP Registration Issues

### Registration Fails with 401 Unauthorized

**Causes:**
- Wrong username/password
- Backend SIP server unreachable
- Authentication realm mismatch

**Debug:**
```bash
# Watch SIP traffic
sudo ngrep -d any -qt -W byline port 5060

# Or use sngrep
sudo apt-get install sngrep
sudo sngrep
```

**Check:**
1. Credentials are correct
2. Backend SIP server is responding
3. Network path to SIP server is open

### Registration Fails with 408 Timeout

**Causes:**
- Backend SIP server not responding
- Firewall blocking outbound SIP
- DNS resolution issue

**Check backend connectivity:**
```bash
# Ping backend
ping sip.mycompany.com

# Check DNS
dig sip.mycompany.com

# Test SIP port
nc -zv sip.mycompany.com 5060

# Trace route
traceroute sip.mycompany.com
```

### Registration Succeeds but Expires Immediately

**Check:**
```bash
# Monitor registrations
kamctl ul show

# Check Kamailio config
grep "max_expires" /etc/kamailio/kamailio.cfg
```

**Adjust in `/etc/kamailio/kamailio.cfg`:**
```
modparam("registrar", "max_expires", 3600)
modparam("registrar", "min_expires", 60)
```

## Audio/Media Issues

### No Audio on Both Sides

**Check rtpengine:**
```bash
# Is rtpengine running?
sudo systemctl status ngcp-rtpengine-daemon

# Check active sessions
rtpengine-ctl list
```

**Check RTP ports:**
```bash
# Are RTP ports open?
sudo ufw status | grep "10000:20000"

# Listen for RTP traffic
sudo tcpdump -i any -n udp portrange 10000-20000
```

**Verify rtpengine configuration:**
```bash
cat /etc/rtpengine/rtpengine.conf | grep -E "interface|port-min|port-max"
```

### One-Way Audio

**Most common cause: NAT/firewall issue**

**Check rtpengine interface configuration:**
```bash
# Should be: interface = PRIVATE_IP!PUBLIC_IP
grep "interface" /etc/rtpengine/rtpengine.conf
```

**Verify public IP:**
```bash
curl https://api.ipify.org
```

**Update if needed:**
```bash
PUBLIC_IP=$(curl -s https://api.ipify.org)
sudo sed -i "s/interface = .*/interface = $(hostname -I | awk '{print $1}')!${PUBLIC_IP}/" /etc/rtpengine/rtpengine.conf
sudo systemctl restart ngcp-rtpengine-daemon
```

**Check NAT detection:**
```bash
# In Kamailio logs, look for:
grep "NAT" /var/log/syslog | tail -20
```

### Poor Audio Quality / Choppy Audio

**Check network:**
```bash
# Packet loss
ping -c 100 sipproxy.yourdomain.com

# Bandwidth
iperf3 -c sipproxy.yourdomain.com
```

**Check CPU usage:**
```bash
top -b -n 1
```

**Check rtpengine performance:**
```bash
rtpengine-ctl list
# Look for dropped packets
```

**Optimize rtpengine:**

In `/etc/rtpengine/rtpengine.conf`:
```
num-threads = 8  # Increase based on CPU cores
table = 0        # Enable kernel forwarding
```

## SSL/TLS Issues

### SSL Certificate Invalid

**Check certificate:**
```bash
sudo certbot certificates

# Or manually
openssl x509 -in /etc/letsencrypt/live/sipproxy.yourdomain.com/cert.pem -text -noout
```

**Renew certificate:**
```bash
sudo certbot renew --force-renewal
sudo systemctl reload kamailio
```

### SSL Certificate Expired

**Auto-renewal not working:**

```bash
# Check timer
sudo systemctl status certbot-renew.timer

# Run manual renewal
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

**Enable auto-renewal:**
```bash
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer
```

### Mixed Content Warnings in Browser

**Issue:** Page loaded over HTTPS, WebSocket uses WSS

**Solution:** Always use `wss://` not `ws://`

```javascript
// Correct
var socket = new JsSIP.WebSocketInterface('wss://sipproxy.yourdomain.com:443');

// Wrong - will cause security warnings
var socket = new JsSIP.WebSocketInterface('ws://sipproxy.yourdomain.com:8080');
```

## Performance Issues

### High CPU Usage

**Check processes:**
```bash
top -b -n 1
ps aux | grep -E "kamailio|rtpengine" | sort -k3 -r
```

**Optimize Kamailio:**

Edit `/etc/kamailio/kamailio.cfg`:
```
# Increase shared memory
shm_mem=512
pkg_mem=16

# Adjust children processes
children=8
```

**Optimize rtpengine:**

Edit `/etc/rtpengine/rtpengine.conf`:
```
num-threads = 8  # Match CPU cores
table = 0        # Use kernel module
```

### High Memory Usage

**Check memory:**
```bash
free -h
ps aux --sort=-%mem | head -10
```

**Adjust Kamailio memory:**
```
shm_mem=256  # Reduce if needed
pkg_mem=8
```

### Too Many Open Files

**Check limits:**
```bash
ulimit -n
cat /proc/$(pidof kamailio)/limits | grep "open files"
```

**Increase limits:**

Edit `/etc/systemd/system/kamailio.service.d/override.conf`:
```ini
[Service]
LimitNOFILE=65536
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart kamailio
```

## Logging and Debugging

### Enable Debug Logging

**Kamailio:**

Edit `/etc/kamailio/kamailio.cfg`:
```
debug=4  # Increase from 2
log_stderror=yes  # For foreground testing
```

Restart:
```bash
sudo systemctl restart kamailio
```

**rtpengine:**

Edit `/etc/rtpengine/rtpengine.conf`:
```
log-level = 7  # Maximum verbosity
```

Restart:
```bash
sudo systemctl restart ngcp-rtpengine-daemon
```

### View Real-Time Logs

**Kamailio:**
```bash
sudo tail -f /var/log/syslog | grep kamailio
```

**rtpengine:**
```bash
sudo journalctl -u ngcp-rtpengine-daemon -f
```

**All SIP traffic:**
```bash
sudo ngrep -d any -qt -W byline port 5060
```

### SIP Traffic Analysis

**Install sngrep:**
```bash
sudo apt-get install sngrep
```

**Use sngrep:**
```bash
sudo sngrep
```

Features:
- Real-time SIP message capture
- Call flow visualization
- Filter by IP, method, etc.

### Packet Capture

**Capture WebSocket traffic:**
```bash
sudo tcpdump -i any -s 0 -w /tmp/websocket.pcap port 443
```

**Capture SIP traffic:**
```bash
sudo tcpdump -i any -s 0 -w /tmp/sip.pcap port 5060
```

**Capture RTP traffic:**
```bash
sudo tcpdump -i any -s 0 -w /tmp/rtp.pcap udp portrange 10000-20000
```

**Analyze with Wireshark:**
```bash
# Install Wireshark
sudo apt-get install wireshark

# Open capture
wireshark /tmp/sip.pcap
```

## Common Error Messages

### "Failed to bind socket"

**Solution:** Port already in use
```bash
sudo netstat -tulpn | grep <PORT>
sudo systemctl stop <conflicting_service>
```

### "Cannot load module"

**Solution:** Module not found
```bash
# Find module location
find /usr -name "*.so" | grep kamailio

# Update mpath in kamailio.cfg
mpath="/usr/lib/x86_64-linux-gnu/kamailio/modules/"
```

### "Database connection failed"

**Solution:** Check database configuration
```bash
# If using text database
ls -l /etc/kamailio/dbtext/

# Permissions
sudo chown -R kamailio:kamailio /etc/kamailio/dbtext/
```

### "TLS handshake failed"

**Solutions:**
1. Check certificate paths in `/etc/kamailio/tls.cfg`
2. Verify certificate permissions
3. Check TLS version compatibility

```bash
# Test TLS
openssl s_client -connect sipproxy.yourdomain.com:5061 -tls1_2
```

## Getting Help

### Collect Debug Information

Run this script to collect system information:

```bash
#!/bin/bash
# Debug info collector
OUTPUT=/tmp/sip-proxy-debug-$(date +%Y%m%d-%H%M%S).txt

{
  echo "=== System Info ==="
  uname -a
  cat /etc/os-release
  
  echo -e "\n=== Service Status ==="
  systemctl status kamailio
  systemctl status ngcp-rtpengine-daemon
  
  echo -e "\n=== Listening Ports ==="
  netstat -tulpn | grep -E "kamailio|rtpengine"
  
  echo -e "\n=== Recent Kamailio Logs ==="
  tail -100 /var/log/syslog | grep kamailio
  
  echo -e "\n=== Recent rtpengine Logs ==="
  journalctl -u ngcp-rtpengine-daemon -n 100
  
  echo -e "\n=== Network Configuration ==="
  ip addr show
  ip route show
  
  echo -e "\n=== Firewall Rules ==="
  ufw status verbose
  
  echo -e "\n=== SSL Certificates ==="
  certbot certificates
  
} > $OUTPUT

echo "Debug info saved to: $OUTPUT"
```

### Support Channels

1. Check documentation
2. Search GitHub issues
3. Create detailed issue with debug info
4. Include relevant log excerpts
5. Describe exact steps to reproduce

## Additional Resources

- [Kamailio Documentation](https://www.kamailio.org/w/documentation/)
- [rtpengine GitHub](https://github.com/sipwise/rtpengine)
- [WebRTC Troubleshooting](https://webrtc.org/getting-started/overview)
- [SIP RFC 3261](https://tools.ietf.org/html/rfc3261)
