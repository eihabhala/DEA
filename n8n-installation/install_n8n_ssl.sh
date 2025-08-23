#!/bin/bash

# n8n Installation with SSL and DodoHook Integration
# by Camlo Technologies
# 
# This script installs n8n with SSL certificates and configures it to work
# seamlessly with DodoHook for professional webhook automation

set -e

echo "🚀 n8n Installation with SSL & DodoHook Integration"
echo "by Camlo Technologies"
echo "=================================================="
echo ""

# Configuration variables
N8N_DOMAIN=${1:-"n8n.yourtrading.com"}
N8N_PORT=${2:-"5678"}
N8N_SSL_PORT=${3:-"443"}
WEBHOOK_DOMAIN=${4:-"webhook.dodohook.com"}
INSTALL_DIR="/opt/n8n"
N8N_USER="n8n"
N8N_DATA_DIR="/home/$N8N_USER/.n8n"

echo "📋 Configuration:"
echo "  n8n Domain: $N8N_DOMAIN"
echo "  n8n Port: $N8N_PORT"
echo "  SSL Port: $N8N_SSL_PORT"
echo "  DodoHook Domain: $WEBHOOK_DOMAIN"
echo "  Install Directory: $INSTALL_DIR"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install required packages
echo "📥 Installing required packages..."
apt install -y curl wget gpg software-properties-common nginx certbot python3-certbot-nginx ufw

# Install Node.js (using NodeSource repository)
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Verify Node.js installation
node_version=$(node --version)
npm_version=$(npm --version)
echo "✅ Node.js installed: $node_version"
echo "✅ npm installed: $npm_version"

# Create n8n user
echo "👤 Creating n8n user..."
if ! id "$N8N_USER" &>/dev/null; then
    useradd -m -s /bin/bash $N8N_USER
    echo "✅ Created user: $N8N_USER"
else
    echo "✅ User $N8N_USER already exists"
fi

# Create installation directory
echo "📁 Creating installation directory..."
mkdir -p $INSTALL_DIR
chown $N8N_USER:$N8N_USER $INSTALL_DIR

# Install n8n globally
echo "🔧 Installing n8n..."
npm install -g n8n

# Create n8n data directory
echo "📁 Creating n8n data directory..."
sudo -u $N8N_USER mkdir -p $N8N_DATA_DIR

# Generate SSL certificates with Let's Encrypt
echo "🔐 Setting up SSL certificates..."
if [[ "$N8N_DOMAIN" != "n8n.yourtrading.com" ]]; then
    # Stop nginx if running
    systemctl stop nginx 2>/dev/null || true
    
    # Get SSL certificate
    certbot certonly --standalone \
        -d $N8N_DOMAIN \
        --agree-tos \
        --non-interactive \
        --email admin@${N8N_DOMAIN#*.} || {
        echo "⚠️  SSL certificate generation failed. Continuing with self-signed..."
        
        # Create self-signed certificate as fallback
        mkdir -p /etc/ssl/certs /etc/ssl/private
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/n8n.key \
            -out /etc/ssl/certs/n8n.crt \
            -subj "/C=US/ST=CA/L=San Francisco/O=Camlo Technologies/CN=$N8N_DOMAIN"
        
        SSL_CERT="/etc/ssl/certs/n8n.crt"
        SSL_KEY="/etc/ssl/private/n8n.key"
    }
    
    if [[ -f "/etc/letsencrypt/live/$N8N_DOMAIN/fullchain.pem" ]]; then
        SSL_CERT="/etc/letsencrypt/live/$N8N_DOMAIN/fullchain.pem"
        SSL_KEY="/etc/letsencrypt/live/$N8N_DOMAIN/privkey.pem"
        echo "✅ Let's Encrypt SSL certificate configured"
    fi
else
    echo "⚠️  Using default domain. Please update N8N_DOMAIN for SSL certificate"
    # Create self-signed certificate
    mkdir -p /etc/ssl/certs /etc/ssl/private
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/n8n.key \
        -out /etc/ssl/certs/n8n.crt \
        -subj "/C=US/ST=CA/L=San Francisco/O=Camlo Technologies/CN=$N8N_DOMAIN"
    
    SSL_CERT="/etc/ssl/certs/n8n.crt"
    SSL_KEY="/etc/ssl/private/n8n.key"
    echo "✅ Self-signed SSL certificate created"
fi

# Configure Nginx as reverse proxy
echo "🌐 Configuring Nginx reverse proxy..."
cat > /etc/nginx/sites-available/n8n << EOF
server {
    listen 80;
    server_name $N8N_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $N8N_DOMAIN;

    ssl_certificate $SSL_CERT;
    ssl_certificate_key $SSL_KEY;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://localhost:$N8N_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Increase timeouts for long-running workflows
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:$N8N_PORT/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t
if [[ $? -ne 0 ]]; then
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Create n8n environment configuration
echo "⚙️  Creating n8n configuration..."
cat > /etc/environment.d/n8n.conf << EOF
# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=$N8N_PORT
N8N_PROTOCOL=https
N8N_EDITOR_BASE_URL=https://$N8N_DOMAIN
WEBHOOK_URL=https://$N8N_DOMAIN
GENERIC_TIMEZONE=UTC

# Security settings
N8N_SECURE_COOKIE=true
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# Performance settings
NODE_OPTIONS=--max-old-space-size=4096
N8N_PAYLOAD_SIZE_MAX=16

# DodoHook Integration
DODOHOOK_WEBHOOK_URL=https://$WEBHOOK_DOMAIN/webhook/n8n
DODOHOOK_DOMAIN=$WEBHOOK_DOMAIN
EOF

# Create n8n systemd service
echo "🔧 Creating n8n systemd service..."
cat > /etc/systemd/system/n8n.service << EOF
[Unit]
Description=n8n - Workflow Automation Tool
After=network.target
Documentation=https://docs.n8n.io

[Service]
Type=simple
User=$N8N_USER
ExecStart=/usr/bin/n8n start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
EnvironmentFile=/etc/environment.d/n8n.conf
WorkingDirectory=$N8N_DATA_DIR
StandardOutput=journal
StandardError=journal
SyslogIdentifier=n8n

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=strict
ReadWritePaths=$N8N_DATA_DIR

[Install]
WantedBy=multi-user.target
EOF

# Configure firewall
echo "🔥 Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Create DodoHook integration script
echo "🔗 Creating DodoHook integration script..."
mkdir -p $INSTALL_DIR/scripts
cat > $INSTALL_DIR/scripts/setup_dodohook_integration.sh << 'SCRIPT_EOF'
#!/bin/bash

# DodoHook Integration Setup for n8n
# This script helps configure n8n workflows to work with DodoHook

echo "🔗 Setting up DodoHook Integration for n8n"
echo "=========================================="
echo ""

WEBHOOK_DOMAIN=${DODOHOOK_DOMAIN:-"webhook.dodohook.com"}

echo "📋 DodoHook Webhook URLs for n8n:"
echo "  Main endpoint: https://$WEBHOOK_DOMAIN/webhook/n8n"
echo "  Workflow-specific: https://$WEBHOOK_DOMAIN/webhook/n8n/{workflow-id}"
echo ""

echo "📝 Example n8n Webhook Configuration:"
echo "  1. Add a 'Webhook' node to your workflow"
echo "  2. Set HTTP Method: POST"
echo "  3. Set Path: /webhook (n8n will generate full URL)"
echo "  4. Configure response: JSON"
echo ""

echo "🔧 Example Trading Signal Workflow:"
cat << 'WORKFLOW_EOF'
{
  "name": "Trading Signal Router",
  "nodes": [
    {
      "name": "DodoHook Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "httpMethod": "POST",
        "path": "trading-signals",
        "responseMode": "responseNode"
      }
    },
    {
      "name": "Process Signal",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// Process trading signal\nconst signal = $json.body;\nif (!signal.action || !signal.symbol) {\n  throw new Error('Invalid signal format');\n}\nreturn {\n  ...signal,\n  timestamp: new Date().toISOString(),\n  processed_by: 'n8n',\n  webhook_source: 'dodohook'\n};"
      }
    },
    {
      "name": "Send to Platform",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "YOUR_TRADING_PLATFORM_API"
      }
    }
  ]
}
WORKFLOW_EOF

echo ""
echo "✅ DodoHook integration guide created"
echo "📚 For more examples, check: https://github.com/xnox-me/DEA/blob/main/Webhook_Server/N8N_INTEGRATION_GUIDE.md"
SCRIPT_EOF

chmod +x $INSTALL_DIR/scripts/setup_dodohook_integration.sh
chown -R $N8N_USER:$N8N_USER $INSTALL_DIR

# Create SSL renewal script
echo "🔄 Creating SSL renewal script..."
cat > /etc/cron.daily/renew-n8n-ssl << 'RENEWAL_EOF'
#!/bin/bash
# Renew SSL certificates for n8n

certbot renew --quiet --no-self-upgrade
if [[ $? -eq 0 ]]; then
    systemctl reload nginx
    logger "n8n SSL certificate renewed successfully"
fi
RENEWAL_EOF

chmod +x /etc/cron.daily/renew-n8n-ssl

# Start and enable services
echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable nginx
systemctl enable n8n
systemctl start nginx
systemctl start n8n

# Wait for services to start
sleep 10

# Check service status
echo "🔍 Checking service status..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx failed to start"
    systemctl status nginx --no-pager
fi

if systemctl is-active --quiet n8n; then
    echo "✅ n8n is running"
else
    echo "❌ n8n failed to start"
    systemctl status n8n --no-pager
fi

# Display completion information
echo ""
echo "🎉 n8n Installation Complete!"
echo "============================="
echo ""
echo "📊 Service Information:"
echo "  n8n URL: https://$N8N_DOMAIN"
echo "  n8n Status: $(systemctl is-active n8n)"
echo "  Nginx Status: $(systemctl is-active nginx)"
echo ""
echo "🔗 DodoHook Integration:"
echo "  Webhook URLs: https://$WEBHOOK_DOMAIN/webhook/n8n"
echo "  Integration Script: $INSTALL_DIR/scripts/setup_dodohook_integration.sh"
echo ""
echo "🔧 Management Commands:"
echo "  Check n8n logs: journalctl -u n8n -f"
echo "  Check nginx logs: tail -f /var/log/nginx/access.log"
echo "  Restart n8n: systemctl restart n8n"
echo "  Restart nginx: systemctl restart nginx"
echo ""
echo "🔐 SSL Certificate:"
if [[ -f "/etc/letsencrypt/live/$N8N_DOMAIN/fullchain.pem" ]]; then
    echo "  Type: Let's Encrypt"
    echo "  Auto-renewal: Enabled (daily check)"
    echo "  Manual renewal: certbot renew"
else
    echo "  Type: Self-signed"
    echo "  Location: $SSL_CERT"
    echo "  Valid for: 365 days"
fi
echo ""
echo "🎯 Next Steps:"
echo "  1. Open https://$N8N_DOMAIN in your browser"
echo "  2. Complete n8n initial setup"
echo "  3. Run: $INSTALL_DIR/scripts/setup_dodohook_integration.sh"
echo "  4. Create your first workflow with DodoHook integration"
echo ""
echo "📚 Documentation:"
echo "  n8n Docs: https://docs.n8n.io"
echo "  DodoHook Guide: https://github.com/xnox-me/DEA/blob/main/Webhook_Server/N8N_INTEGRATION_GUIDE.md"
echo ""
echo "✅ Installation completed successfully!"