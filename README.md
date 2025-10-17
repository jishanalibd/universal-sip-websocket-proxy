# Universal SIP WebSocket Proxy

A production-ready SIP-over-WebSocket (WSS) provider model that enables users to connect from browsers or web applications using their own SIP credentials.

## 🎯 Overview

This project provides a **universal SIP WebSocket gateway** that allows web-based SIP clients (like Browser-Phone, JsSIP, SIP.js) to connect to **any backend SIP server** without being locked into a specific PBX.

### User Flow

1. User visits your web app (e.g., `https://phone.yourdomain.com`)
2. They enter their SIP credentials:
   - **SIP domain**: `sip.mycompany.com`
   - **Username**: `user123`
   - **Password**: `secret`
3. Browser connects via `wss://sipproxy.yourdomain.com:443`
4. Kamailio proxy accepts WSS → converts to standard SIP UDP/TCP → forwards to their SIP server
5. Media flows through rtpengine for WebRTC compatibility

## 🧩 Components

| Component | Role | Notes |
|-----------|------|-------|
| **Kamailio** | WSS proxy + TLS terminator | Handles SIP over WebSocket |
| **rtpengine** | Media relay | Converts SRTP ↔ RTP for WebRTC |
| **Let's Encrypt** | TLS certificates | Auto-renew for secure WSS |
| **Browser Phone UI** | Web client (optional) | JsSIP or SIP.js based |
| **Any SIP server** | Backend destination | Receives REGISTER, INVITE |

## 📋 Prerequisites

- Ubuntu 22.04 or 24.04 LTS
- Domain name pointing to your server (e.g., `sipproxy.yourdomain.com`)
- Root or sudo access
- Ports: 80, 443, 8080, 5060-5061 (UDP/TCP), 10000-20000 (UDP for RTP)

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/jishanalibd/universal-sip-websocket-proxy.git
cd universal-sip-websocket-proxy
```

### 2. Run the installation script

```bash
sudo bash scripts/install.sh
```

This will:
- Install Kamailio and rtpengine
- Configure firewall rules
- Set up systemd services
- Install required dependencies

### 3. Configure your domain

Edit `/etc/kamailio/kamailio.cfg` and update:

```
#!define DOMAIN "sipproxy.yourdomain.com"
```

### 4. Get SSL certificates

```bash
sudo bash scripts/setup-ssl.sh sipproxy.yourdomain.com your-email@domain.com
```

### 5. Start services

```bash
sudo systemctl start kamailio
sudo systemctl start rtpengine
```

## 📖 Detailed Installation

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for step-by-step installation instructions.

For quick command reference, see [docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md).

## 🔧 Configuration

### Kamailio Configuration

The main Kamailio configuration is located at:
- `/etc/kamailio/kamailio.cfg` - Main configuration
- `/etc/kamailio/tls.cfg` - TLS settings

### rtpengine Configuration

Configuration file: `/etc/rtpengine/rtpengine.conf`

Key settings:
- Interface for RTP relay
- Port ranges
- Kernel forwarding

## 🌐 Client Configuration

### Browser-Phone Example

```javascript
var config = {
  websocket_proxy_url: 'wss://sipproxy.yourdomain.com:443',
  domain: 'sip.mycompany.com',  // User's actual SIP domain
  username: 'user123',
  password: 'secret',
  display_name: 'John Doe'
};
```

### JsSIP Example

```javascript
var socket = new JsSIP.WebSocketInterface('wss://sipproxy.yourdomain.com:443');
var configuration = {
  sockets: [socket],
  uri: 'sip:user123@sip.mycompany.com',
  password: 'secret'
};

var ua = new JsSIP.UA(configuration);
ua.start();
```

See [docs/CLIENT-EXAMPLES.md](docs/CLIENT-EXAMPLES.md) for more examples.

## 🔒 Security

- TLS 1.2+ required for WSS connections
- Automatic certificate renewal via Let's Encrypt
- SIP digest authentication
- Rate limiting and anti-flood protection
- IP-based access control (optional)

## 🐛 Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

### Quick Debug

```bash
# Check Kamailio logs
sudo tail -f /var/log/syslog | grep kamailio

# Check rtpengine logs
sudo journalctl -u rtpengine -f

# Test WebSocket connection
wscat -c wss://sipproxy.yourdomain.com:443
```

### Test Client

A ready-to-use web-based test client is included in the `examples/` directory:

```bash
# Serve the test client
cd examples
python3 -m http.server 8000
# Open http://localhost:8000/test-client.html in your browser
```

The test client allows you to:
- Connect to your WebSocket proxy
- Register with any SIP server
- Make and receive calls
- View real-time logs

See [examples/README.md](examples/README.md) for more details.

## 📁 Project Structure

```
.
├── config/
│   ├── kamailio/           # Kamailio configuration files
│   ├── rtpengine/          # rtpengine configuration
│   └── systemd/            # systemd service files
├── scripts/
│   ├── install.sh          # Main installation script
│   ├── setup-ssl.sh        # SSL certificate setup
│   └── firewall.sh         # Firewall configuration
├── docs/
│   ├── INSTALLATION.md     # Detailed installation guide
│   ├── CLIENT-EXAMPLES.md  # Client configuration examples
│   └── TROUBLESHOOTING.md  # Troubleshooting guide
├── examples/
│   ├── test-client.html    # Web-based test client
│   └── README.md           # Examples documentation
└── README.md
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [Kamailio](https://www.kamailio.org/) - SIP server
- [rtpengine](https://github.com/sipwise/rtpengine) - RTP/media proxy
- [Browser-Phone](https://github.com/InnovateAsterisk/Browser-Phone/) - WebRTC phone UI
- [JsSIP](https://jssip.net/) - JavaScript SIP library

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check the [documentation](docs/)
- Review [troubleshooting guide](docs/TROUBLESHOOTING.md)

## ⚡ Performance Tips

- Use UDP for SIP signaling when possible
- Configure kernel RTP forwarding in rtpengine
- Enable Kamailio's shared memory optimizations
- Use SSD storage for better I/O performance
- Consider using multiple rtpengine instances for load balancing

## 🎓 Architecture

```
┌─────────────┐         WSS (443)        ┌──────────────┐
│   Browser   │◄─────────────────────────►│   Kamailio   │
│  (JsSIP)    │                           │  WSS Proxy   │
└─────────────┘                           └──────┬───────┘
      ▲                                          │
      │                                          │ SIP UDP/TCP
      │ SRTP                                     │
      │                                          ▼
┌─────┴───────┐                          ┌──────────────┐
│  rtpengine  │◄─────────────────────────►│  Backend SIP │
│ Media Relay │         RTP              │    Server    │
└─────────────┘                          └──────────────┘
```

The proxy acts as a transparent gateway, forwarding SIP messages to any backend SIP server while handling WebSocket/TLS on the client side and RTP/SRTP media conversion.
