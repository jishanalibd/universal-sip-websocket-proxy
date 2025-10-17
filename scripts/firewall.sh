#!/bin/bash
#
# Firewall Configuration Script
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

log_info "Configuring firewall rules for SIP WebSocket Proxy..."

# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
    log_info "Installing UFW (Uncomplicated Firewall)..."
    apt-get update
    apt-get install -y ufw
fi

# Reset UFW to default
log_warn "This will reset firewall to default settings"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

ufw --force reset
ufw --force enable

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (be careful not to lock yourself out!)
log_info "Allowing SSH (port 22)..."
ufw allow 22/tcp comment 'SSH'

# Allow HTTP (for Let's Encrypt certificate validation)
log_info "Allowing HTTP (port 80)..."
ufw allow 80/tcp comment 'HTTP - Let\'s Encrypt'

# Allow HTTPS
log_info "Allowing HTTPS (port 443)..."
ufw allow 443/tcp comment 'HTTPS - WSS'

# Allow WebSocket (port 8080)
log_info "Allowing WebSocket (port 8080)..."
ufw allow 8080/tcp comment 'WebSocket'

# Allow SIP signaling
log_info "Allowing SIP signaling ports..."
ufw allow 5060/udp comment 'SIP UDP'
ufw allow 5060/tcp comment 'SIP TCP'
ufw allow 5061/tcp comment 'SIP TLS'

# Allow RTP/RTCP media
log_info "Allowing RTP/RTCP ports (10000-20000/udp)..."
ufw allow 10000:20000/udp comment 'RTP/RTCP Media'

# Optional: Allow specific IP ranges only (uncomment and modify as needed)
# log_info "Restricting SIP access to specific IP ranges..."
# ufw delete allow 5060/udp
# ufw delete allow 5060/tcp
# ufw allow from 203.0.113.0/24 to any port 5060 proto udp comment 'SIP UDP - Trusted Network'
# ufw allow from 203.0.113.0/24 to any port 5060 proto tcp comment 'SIP TCP - Trusted Network'

# Enable and reload
ufw --force enable
ufw reload

log_info ""
log_info "=========================================="
log_info "Firewall Configuration Complete!"
log_info "=========================================="
log_info ""
log_info "Firewall Status:"
ufw status verbose
log_info ""
log_info "Active Rules:"
log_info "  - SSH: 22/tcp"
log_info "  - HTTP: 80/tcp (Let's Encrypt)"
log_info "  - HTTPS/WSS: 443/tcp"
log_info "  - WebSocket: 8080/tcp"
log_info "  - SIP UDP: 5060/udp"
log_info "  - SIP TCP: 5060/tcp"
log_info "  - SIP TLS: 5061/tcp"
log_info "  - RTP/RTCP: 10000-20000/udp"
log_info ""
log_info "To view detailed status:"
log_info "  sudo ufw status numbered"
log_info ""
log_info "To delete a rule by number:"
log_info "  sudo ufw delete <number>"
log_info ""
