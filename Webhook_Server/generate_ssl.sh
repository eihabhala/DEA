#!/bin/bash

# SSL Certificate Generator for Custom Tunnel Server
# This script generates self-signed SSL certificates for your tunnel server

echo "🔐 SSL Certificate Generator for DodoHook"
echo "by Camlo Technologies"
echo "==========================================="

# Create certs directory
mkdir -p certs
cd certs

# Configuration for certificate
DOMAIN=${1:-webhook.yourtrading.com}
COUNTRY="US"
STATE="California"
CITY="San Francisco"
ORGANIZATION="Trading Expert"
ORG_UNIT="IT Department"
EMAIL="admin@yourtrading.com"

echo "📋 Certificate Details:"
echo "Domain: $DOMAIN"
echo "Country: $COUNTRY"
echo "State: $STATE"
echo "City: $CITY"
echo "Organization: $ORGANIZATION"
echo ""

# Generate private key
echo "🔑 Generating private key..."
openssl genrsa -out server.key 2048

# Generate certificate signing request
echo "📝 Creating certificate signing request..."
openssl req -new -key server.key -out server.csr -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$DOMAIN/emailAddress=$EMAIL"

# Create certificate extensions file
echo "📄 Creating certificate extensions..."
cat > server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = localhost
DNS.4 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generate self-signed certificate
echo "🎫 Generating self-signed certificate..."
openssl x509 -req -in server.csr -signkey server.key -out server.crt -days 365 -extensions v3_req -extfile server.ext

# Set proper permissions
chmod 600 server.key
chmod 644 server.crt

# Verify certificate
echo ""
echo "✅ Certificate generated successfully!"
echo ""
echo "📋 Certificate Information:"
openssl x509 -in server.crt -text -noout | grep -A 5 "Subject:"
echo ""
openssl x509 -in server.crt -text -noout | grep -A 10 "Subject Alternative Name"
echo ""

echo "📁 Certificate Files:"
echo "  Private Key: $(pwd)/server.key"
echo "  Certificate: $(pwd)/server.crt"
echo ""

echo "🔧 Configuration:"
echo "Update your tunnel_config.yaml with:"
echo "  ssl_cert: $(pwd)/server.crt"
echo "  ssl_key: $(pwd)/server.key"
echo ""

echo "⚠️  Important Notes:"
echo "1. This is a self-signed certificate - browsers will show a warning"
echo "2. For production, get a certificate from Let's Encrypt or a CA"
echo "3. Update the domain name in tunnel_config.yaml"
echo "4. Configure your DNS to point to this server"
echo ""

echo "🎯 Next Steps:"
echo "1. Update tunnel_config.yaml with your domain"
echo "2. Configure your firewall to allow port 443"
echo "3. Start the tunnel server: python3 custom_tunnel_server.py"
echo "4. Use https://$DOMAIN/webhook in TradingView"