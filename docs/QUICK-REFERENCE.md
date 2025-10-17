# Quick Reference Guide

## Installation Commands

### One-Line Install
```bash
sudo bash scripts/install.sh
```

### Configure Domain
```bash
sudo sed -i 's/sipproxy.yourdomain.com/YOUR_DOMAIN/g' /etc/kamailio/kamailio.cfg
```

### Setup SSL
```bash
sudo bash scripts/setup-ssl.sh YOUR_DOMAIN your-email@domain.com
```

### Start Services
```bash
sudo systemctl start ngcp-rtpengine-daemon
sudo systemctl start kamailio
```

## Service Management

### Status
```bash
sudo systemctl status kamailio
sudo systemctl status ngcp-rtpengine-daemon
```

### Start
```bash
sudo systemctl start kamailio
sudo systemctl start ngcp-rtpengine-daemon
```

### Stop
```bash
sudo systemctl stop kamailio
sudo systemctl stop ngcp-rtpengine-daemon
```

### Restart
```bash
sudo systemctl restart kamailio
sudo systemctl restart ngcp-rtpengine-daemon
```

### Enable Auto-start
```bash
sudo systemctl enable kamailio
sudo systemctl enable ngcp-rtpengine-daemon
```

## Log Files

### Kamailio Logs
```bash
# Real-time
sudo tail -f /var/log/syslog | grep kamailio

# Last 100 lines
sudo tail -100 /var/log/syslog | grep kamailio

# Search for errors
sudo grep -i error /var/log/syslog | grep kamailio
```

### rtpengine Logs
```bash
# Real-time
sudo journalctl -u ngcp-rtpengine-daemon -f

# Last 100 lines
sudo journalctl -u ngcp-rtpengine-daemon -n 100

# Since boot
sudo journalctl -u ngcp-rtpengine-daemon -b
```

## Testing

### Test WebSocket Connection
```bash
wscat -c wss://sipproxy.yourdomain.com:443
```

### Check Listening Ports
```bash
sudo netstat -tulpn | grep kamailio
sudo netstat -tulpn | grep rtpengine
```

### Check Active Sessions
```bash
# Kamailio registrations
kamctl ul show

# rtpengine sessions
rtpengine-ctl list
```

### SIP Traffic Monitoring
```bash
# Install sngrep
sudo apt-get install sngrep

# Monitor SIP traffic
sudo sngrep
```

### Packet Capture
```bash
# WebSocket
sudo tcpdump -i any -s 0 -w websocket.pcap port 443

# SIP
sudo tcpdump -i any -s 0 -w sip.pcap port 5060

# RTP
sudo tcpdump -i any -s 0 -w rtp.pcap udp portrange 10000-20000
```

## Configuration Files

### Main Kamailio Config
```bash
sudo vim /etc/kamailio/kamailio.cfg
```

### TLS Config
```bash
sudo vim /etc/kamailio/tls.cfg
```

### rtpengine Config
```bash
sudo vim /etc/rtpengine/rtpengine.conf
```

### Test Configuration
```bash
# Kamailio
sudo kamailio -c

# rtpengine
sudo rtpengine --config-file=/etc/rtpengine/rtpengine.conf --foreground
```

## SSL Certificates

### View Certificates
```bash
sudo certbot certificates
```

### Renew Certificate
```bash
sudo certbot renew
```

### Test Renewal
```bash
sudo certbot renew --dry-run
```

### Manual Certificate
```bash
sudo certbot certonly --standalone -d sipproxy.yourdomain.com
```

## Firewall

### Check Status
```bash
sudo ufw status verbose
```

### Allow Port
```bash
sudo ufw allow 5060/udp
```

### Delete Rule
```bash
sudo ufw status numbered
sudo ufw delete <number>
```

### Reset Firewall
```bash
sudo ufw reset
sudo bash scripts/firewall.sh
```

## Performance Tuning

### Increase Kamailio Memory
Edit `/etc/kamailio/kamailio.cfg`:
```
shm_mem=512
pkg_mem=16
```

### Increase rtpengine Threads
Edit `/etc/rtpengine/rtpengine.conf`:
```
num-threads = 8
```

### Increase File Descriptors
```bash
sudo mkdir -p /etc/systemd/system/kamailio.service.d/
sudo cp config/systemd/kamailio-override.conf /etc/systemd/system/kamailio.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart kamailio
```

## Backup & Restore

### Backup Configuration
```bash
sudo tar -czf kamailio-backup-$(date +%Y%m%d).tar.gz /etc/kamailio
sudo tar -czf rtpengine-backup-$(date +%Y%m%d).tar.gz /etc/rtpengine
```

### Restore Configuration
```bash
sudo tar -xzf kamailio-backup-YYYYMMDD.tar.gz -C /
sudo systemctl restart kamailio
```

## Network Information

### Get IP Addresses
```bash
# Private IP
hostname -I | awk '{print $1}'

# Public IP
curl https://api.ipify.org
```

### Get Network Interface
```bash
ip route | grep default | awk '{print $5}'
```

### Test Connectivity
```bash
# Test backend SIP server
nc -zv sip.example.com 5060

# Test DNS
dig sipproxy.yourdomain.com
```

## Debugging

### Enable Debug Mode
Edit `/etc/kamailio/kamailio.cfg`:
```
debug=4
log_stderror=yes
```

### Run Kamailio in Foreground
```bash
sudo systemctl stop kamailio
sudo kamailio -DD -E
```

### Check for Core Dumps
```bash
sudo coredumpctl list
sudo coredumpctl info kamailio
```

## Client Configuration

### JsSIP
```javascript
var socket = new JsSIP.WebSocketInterface('wss://sipproxy.yourdomain.com:443');
var configuration = {
  sockets: [socket],
  uri: 'sip:user@domain.com',
  password: 'secret'
};
var ua = new JsSIP.UA(configuration);
ua.start();
```

### Test Client
```bash
cd examples
python3 -m http.server 8000
# Open http://localhost:8000/test-client.html
```

## Common Issues

### WebSocket Won't Connect
```bash
# Check service
sudo systemctl status kamailio

# Check port
sudo netstat -tulpn | grep :443

# Test SSL
openssl s_client -connect sipproxy.yourdomain.com:443
```

### No Audio
```bash
# Check rtpengine
sudo systemctl status ngcp-rtpengine-daemon
rtpengine-ctl list

# Check firewall
sudo ufw status | grep 10000:20000

# Check interface config
grep interface /etc/rtpengine/rtpengine.conf
```

### Registration Fails
```bash
# Check logs
sudo tail -f /var/log/syslog | grep kamailio

# Monitor SIP traffic
sudo sngrep

# Test backend connectivity
nc -zv sip.backend.com 5060
```

## Useful Commands

### Kamailio
```bash
# Check syntax
sudo kamailio -c

# Show runtime config
kamctl cfg list

# Monitor statistics
kamcmd stats.get_statistics all
```

### rtpengine
```bash
# List sessions
rtpengine-ctl list

# Show statistics
rtpengine-ctl query
```

## Resources

- Main Documentation: [docs/INSTALLATION.md](docs/INSTALLATION.md)
- Troubleshooting: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Client Examples: [docs/CLIENT-EXAMPLES.md](docs/CLIENT-EXAMPLES.md)
- Test Client: [examples/test-client.html](examples/test-client.html)

## Support

- Check logs first
- Search documentation
- Review troubleshooting guide
- Create GitHub issue with:
  - OS version
  - Error messages
  - Configuration (sanitized)
  - Steps to reproduce
