#!/bin/bash
#
# SSL Certificate Setup Script using Let's Encrypt
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

# Check arguments
if [ "$#" -lt 2 ]; then
    log_error "Usage: $0 <domain> <email>"
    log_info "Example: $0 sipproxy.yourdomain.com admin@yourdomain.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2

log_info "Setting up SSL certificates for domain: $DOMAIN"
log_info "Contact email: $EMAIL"

# Install certbot
log_info "Installing certbot..."
if ! command -v certbot &> /dev/null; then
    apt-get update
    apt-get install -y certbot
    log_info "Certbot installed"
else
    log_info "Certbot already installed"
fi

# Stop Kamailio if running (to free up port 80)
if systemctl is-active --quiet kamailio; then
    log_info "Stopping Kamailio temporarily..."
    systemctl stop kamailio
    RESTART_KAMAILIO=1
fi

# Get certificate using standalone mode
log_info "Obtaining SSL certificate from Let's Encrypt..."
certbot certonly \
    --standalone \
    --preferred-challenges http \
    --agree-tos \
    --email "$EMAIL" \
    --non-interactive \
    -d "$DOMAIN"

if [ $? -eq 0 ]; then
    log_info "Certificate obtained successfully!"
else
    log_error "Failed to obtain certificate"
    exit 1
fi

# Update Kamailio TLS config
log_info "Updating Kamailio TLS configuration..."
if [ -f /etc/kamailio/tls.cfg ]; then
    sed -i "s/DOMAIN/${DOMAIN}/g" /etc/kamailio/tls.cfg
    log_info "TLS config updated"
else
    log_warn "TLS config file not found at /etc/kamailio/tls.cfg"
fi

# Update Kamailio main config
if [ -f /etc/kamailio/kamailio.cfg ]; then
    # Check if DOMAIN is still set to default
    if grep -q '#!define DOMAIN "sipproxy.yourdomain.com"' /etc/kamailio/kamailio.cfg; then
        sed -i "s/sipproxy.yourdomain.com/${DOMAIN}/g" /etc/kamailio/kamailio.cfg
        log_info "Kamailio config updated with domain"
    fi
fi

# Set up automatic renewal
log_info "Setting up automatic certificate renewal..."
cat > /etc/systemd/system/certbot-renew.service << EOF
[Unit]
Description=Certbot Renewal
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --deploy-hook "systemctl reload kamailio"
EOF

cat > /etc/systemd/system/certbot-renew.timer << EOF
[Unit]
Description=Run certbot renewal twice daily

[Timer]
OnCalendar=*-*-* 00,12:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable certbot-renew.timer
systemctl start certbot-renew.timer

log_info "Auto-renewal timer configured"

# Create a post-renewal hook
mkdir -p /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/kamailio-reload.sh << 'EOF'
#!/bin/bash
systemctl reload kamailio
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/kamailio-reload.sh

# Restart Kamailio if it was running
if [ "$RESTART_KAMAILIO" == "1" ]; then
    log_info "Starting Kamailio..."
    systemctl start kamailio
fi

log_info ""
log_info "=========================================="
log_info "SSL Setup Completed!"
log_info "=========================================="
log_info ""
log_info "Certificate details:"
log_info "  Domain: $DOMAIN"
log_info "  Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
log_info "  Private key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
log_info ""
log_info "Auto-renewal is configured to run twice daily"
log_info ""
log_info "To manually renew:"
log_info "  sudo certbot renew"
log_info ""
log_info "To check renewal status:"
log_info "  sudo certbot certificates"
log_info ""
log_info "Next steps:"
log_info "1. Start/restart services:"
log_info "   sudo systemctl restart rtpengine"
log_info "   sudo systemctl restart kamailio"
log_info ""
log_info "2. Test WebSocket connection:"
log_info "   wscat -c wss://$DOMAIN:443"
log_info ""
