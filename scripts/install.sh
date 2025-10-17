#!/bin/bash
#
# Universal SIP WebSocket Proxy - Installation Script
# For Ubuntu 22.04 and 24.04
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
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

log_info "Starting Universal SIP WebSocket Proxy installation..."

# Detect Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    log_error "Cannot detect OS version"
    exit 1
fi

log_info "Detected OS: $OS $VER"

if [[ "$OS" != "Ubuntu" ]]; then
    log_error "This script is designed for Ubuntu. Detected: $OS"
    exit 1
fi

if [[ "$VER" != "22.04" && "$VER" != "24.04" ]]; then
    log_warn "This script is tested on Ubuntu 22.04 and 24.04. You have version $VER"
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
log_info "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install dependencies
log_info "Installing dependencies..."
apt-get install -y \
    wget \
    curl \
    gnupg2 \
    build-essential \
    git \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    ufw \
    net-tools \
    dkms \
    linux-headers-$(uname -r)

# Add Kamailio repository
log_info "Adding Kamailio repository..."
if [[ "$VER" == "22.04" ]]; then
    wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | gpg --dearmor > /usr/share/keyrings/kamailio-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/kamailio-archive-keyring.gpg] http://deb.kamailio.org/kamailio58 jammy main" > /etc/apt/sources.list.d/kamailio.list
elif [[ "$VER" == "24.04" ]]; then
    wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | gpg --dearmor > /usr/share/keyrings/kamailio-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/kamailio-archive-keyring.gpg] http://deb.kamailio.org/kamailio58 noble main" > /etc/apt/sources.list.d/kamailio.list
fi

apt-get update

# Install Kamailio
log_info "Installing Kamailio..."
apt-get install -y \
    kamailio \
    kamailio-websocket-modules \
    kamailio-tls-modules \
    kamailio-json-modules \
    kamailio-utils-modules \
    kamailio-extra-modules

# Install rtpengine
log_info "Installing rtpengine..."

# Add rtpengine repository
wget -O- https://dfx.at/sipwise-signing-key.gpg | gpg --dearmor > /usr/share/keyrings/sipwise-archive-keyring.gpg

if [[ "$VER" == "22.04" ]]; then
    echo "deb [signed-by=/usr/share/keyrings/sipwise-archive-keyring.gpg] https://deb.sipwise.com/spce/mr11.5 jammy main" > /etc/apt/sources.list.d/sipwise.list
elif [[ "$VER" == "24.04" ]]; then
    echo "deb [signed-by=/usr/share/keyrings/sipwise-archive-keyring.gpg] https://deb.sipwise.com/spce/mr11.5 noble main" > /etc/apt/sources.list.d/sipwise.list
fi

apt-get update
apt-get install -y ngcp-rtpengine-daemon ngcp-rtpengine-kernel-dkms ngcp-rtpengine-utils

# Load kernel module
log_info "Loading rtpengine kernel module..."
modprobe xt_RTPENGINE || log_warn "Could not load xt_RTPENGINE kernel module (may not be critical)"
echo "xt_RTPENGINE" > /etc/modules-load.d/rtpengine.conf

# Configure firewall
log_info "Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 8080/tcp comment 'WebSocket'
    ufw allow 5060/udp comment 'SIP UDP'
    ufw allow 5060/tcp comment 'SIP TCP'
    ufw allow 5061/tcp comment 'SIP TLS'
    ufw allow 10000:20000/udp comment 'RTP/RTCP'
    ufw reload
    log_info "Firewall configured"
else
    log_warn "UFW not found, skipping firewall configuration"
fi

# Get network interface and IPs
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
PRIVATE_IP=$(ip addr show $IFACE | grep "inet " | awk '{print $2}' | cut -d/ -f1)
PUBLIC_IP=$(curl -s https://api.ipify.org || echo "UNKNOWN")

log_info "Network interface: $IFACE"
log_info "Private IP: $PRIVATE_IP"
log_info "Public IP: $PUBLIC_IP"

# Copy configuration files
log_info "Installing configuration files..."

# Create backup directory
mkdir -p /etc/kamailio/backup
mkdir -p /etc/rtpengine/backup

# Backup existing configs if they exist
if [ -f /etc/kamailio/kamailio.cfg ]; then
    cp /etc/kamailio/kamailio.cfg /etc/kamailio/backup/kamailio.cfg.$(date +%Y%m%d-%H%M%S)
fi

if [ -f /etc/rtpengine/rtpengine.conf ]; then
    cp /etc/rtpengine/rtpengine.conf /etc/rtpengine/backup/rtpengine.conf.$(date +%Y%m%d-%H%M%S)
fi

# Copy our configuration files
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"

if [ -f "$SCRIPT_DIR/config/kamailio/kamailio.cfg" ]; then
    cp "$SCRIPT_DIR/config/kamailio/kamailio.cfg" /etc/kamailio/kamailio.cfg
    log_info "Kamailio config installed"
else
    log_warn "Kamailio config file not found in repository"
fi

if [ -f "$SCRIPT_DIR/config/kamailio/tls.cfg" ]; then
    cp "$SCRIPT_DIR/config/kamailio/tls.cfg" /etc/kamailio/tls.cfg
    log_info "Kamailio TLS config installed"
else
    log_warn "Kamailio TLS config file not found in repository"
fi

if [ -f "$SCRIPT_DIR/config/rtpengine/rtpengine.conf" ]; then
    cp "$SCRIPT_DIR/config/rtpengine/rtpengine.conf" /etc/rtpengine/rtpengine.conf
    
    # Update rtpengine config with actual IPs
    sed -i "s/PRIVATE_IP/${PRIVATE_IP}/g" /etc/rtpengine/rtpengine.conf
    sed -i "s/PUBLIC_IP/${PUBLIC_IP}/g" /etc/rtpengine/rtpengine.conf
    log_info "rtpengine config installed and updated"
else
    log_warn "rtpengine config file not found in repository"
fi

# Set proper permissions
chown kamailio:kamailio /etc/kamailio/kamailio.cfg
chmod 644 /etc/kamailio/kamailio.cfg

# Enable services (don't start yet - need SSL certs first)
log_info "Enabling services..."
systemctl enable kamailio
systemctl enable ngcp-rtpengine-daemon

log_info ""
log_info "=========================================="
log_info "Installation completed successfully!"
log_info "=========================================="
log_info ""
log_info "Next steps:"
log_info "1. Edit /etc/kamailio/kamailio.cfg and set your domain:"
log_info "   #!define DOMAIN \"sipproxy.yourdomain.com\""
log_info ""
log_info "2. Run SSL setup script:"
log_info "   sudo bash scripts/setup-ssl.sh sipproxy.yourdomain.com your-email@domain.com"
log_info ""
log_info "3. Start services:"
log_info "   sudo systemctl start rtpengine"
log_info "   sudo systemctl start kamailio"
log_info ""
log_info "4. Check service status:"
log_info "   sudo systemctl status kamailio"
log_info "   sudo systemctl status rtpengine"
log_info ""
log_info "For more information, see docs/INSTALLATION.md"
log_info ""
