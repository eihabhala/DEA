#!/bin/bash

# Django Trading Dashboard Installation Script
# Professional ML Trading Information Display Platform
# by Camlo Technologies

set -e

echo "🌐 Django Trading Dashboard Installation"
echo "Professional ML Trading Information Platform"
echo "by Camlo Technologies"
echo "==========================================="
echo ""

# Configuration
DJANGO_PROJECT="trading_dashboard"
DJANGO_APP="ml_analytics"
DJANGO_DOMAIN=${1:-"dashboard.yourtrading.com"}
DJANGO_PORT=${2:-"8000"}
DJANGO_SSL_PORT=${3:-"443"}
DODOHOOK_DOMAIN=${4:-"webhook.dodohook.com"}
N8N_DOMAIN=${5:-"n8n.yourtrading.com"}
INSTALL_DIR="/opt/trading_dashboard"
DJANGO_USER="django"
VENV_PATH="$INSTALL_DIR/venv"

echo "📋 Configuration:"
echo "  Django Domain: $DJANGO_DOMAIN"
echo "  Django Port: $DJANGO_PORT"
echo "  SSL Port: $DJANGO_SSL_PORT"
echo "  DodoHook Domain: $DODOHOOK_DOMAIN"
echo "  n8n Domain: $N8N_DOMAIN"
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
apt install -y python3 python3-pip python3-venv python3-dev \
    nginx postgresql postgresql-contrib redis-server \
    certbot python3-certbot-nginx git curl wget \
    build-essential libpq-dev

# Install Node.js for frontend assets
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "✅ System packages installed"

# Create Django user
echo "👤 Creating Django user..."
if ! id "$DJANGO_USER" &>/dev/null; then
    useradd -m -s /bin/bash $DJANGO_USER
    echo "✅ Created user: $DJANGO_USER"
else
    echo "✅ User $DJANGO_USER already exists"
fi

# Create installation directory
echo "📁 Creating installation directory..."
mkdir -p $INSTALL_DIR
chown $DJANGO_USER:$DJANGO_USER $INSTALL_DIR

# Create Python virtual environment
echo "🐍 Creating Python virtual environment..."
sudo -u $DJANGO_USER python3 -m venv $VENV_PATH
echo "✅ Virtual environment created"

# Install Python packages
echo "📦 Installing Python packages..."
sudo -u $DJANGO_USER $VENV_PATH/bin/pip install --upgrade pip

# Create requirements file
cat > $INSTALL_DIR/requirements.txt << EOF
# Django Trading Dashboard Requirements
Django==4.2.7
djangorestframework==3.14.0
django-cors-headers==4.3.1
django-environ==0.11.2
django-extensions==3.2.3
django-crispy-forms==2.1
crispy-bootstrap5==0.7

# Database
psycopg2-binary==2.9.9
redis==5.0.1
django-redis==5.4.0

# API and Data Processing
requests==2.31.0
celery==5.3.4
pandas==2.1.4
numpy==1.24.4
scikit-learn==1.3.2
matplotlib==3.8.2
seaborn==0.13.0
plotly==5.17.0

# WebSocket support
channels==4.0.0
channels-redis==4.1.0
daphne==4.0.0

# Authentication and Security
djangorestframework-simplejwt==5.3.0
django-allauth==0.57.0
python-decouple==3.8

# Monitoring and Logging
django-debug-toolbar==4.2.0
sentry-sdk==1.38.0

# Trading and Financial Data
yfinance==0.2.28
alpha-vantage==2.3.1
python-binance==1.0.19

# AI and ML Libraries
tensorflow==2.15.0
torch==2.1.2
transformers==4.36.2
textblob==0.17.1
vaderSentiment==3.3.2

# News and Social Media
newsapi-python==0.2.7
tweepy==4.14.0
beautifulsoup4==4.12.2

# Utilities
python-dotenv==1.0.0
Pillow==10.1.0
whitenoise==6.6.0
gunicorn==21.2.0
uvicorn==0.24.0
websockets==12.0
EOF

sudo -u $DJANGO_USER $VENV_PATH/bin/pip install -r $INSTALL_DIR/requirements.txt
echo "✅ Python packages installed"

# Create Django project
echo "🔧 Creating Django project..."
cd $INSTALL_DIR
sudo -u $DJANGO_USER $VENV_PATH/bin/django-admin startproject $DJANGO_PROJECT .
sudo -u $DJANGO_USER $VENV_PATH/bin/python manage.py startapp $DJANGO_APP

echo "✅ Django project created"

# Configure PostgreSQL
echo "🗄️ Configuring PostgreSQL..."
sudo -u postgres psql << EOF
CREATE DATABASE trading_dashboard_db;
CREATE USER trading_dashboard_user WITH PASSWORD 'trading_dashboard_password_change_me';
ALTER ROLE trading_dashboard_user SET client_encoding TO 'utf8';
ALTER ROLE trading_dashboard_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE trading_dashboard_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE trading_dashboard_db TO trading_dashboard_user;
\q
EOF

echo "✅ PostgreSQL configured"

# Generate SSL certificates
echo "🔐 Setting up SSL certificates..."
if [[ "$DJANGO_DOMAIN" != "dashboard.yourtrading.com" ]]; then
    # Stop nginx if running
    systemctl stop nginx 2>/dev/null || true
    
    # Get SSL certificate
    certbot certonly --standalone \
        -d $DJANGO_DOMAIN \
        --agree-tos \
        --non-interactive \
        --email admin@${DJANGO_DOMAIN#*.} || {
        echo "⚠️  SSL certificate generation failed. Continuing with self-signed..."
        
        # Create self-signed certificate as fallback
        mkdir -p /etc/ssl/certs /etc/ssl/private
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/django.key \
            -out /etc/ssl/certs/django.crt \
            -subj "/C=US/ST=CA/L=San Francisco/O=Camlo Technologies/CN=$DJANGO_DOMAIN"
        
        SSL_CERT="/etc/ssl/certs/django.crt"
        SSL_KEY="/etc/ssl/private/django.key"
    }
    
    if [[ -f "/etc/letsencrypt/live/$DJANGO_DOMAIN/fullchain.pem" ]]; then
        SSL_CERT="/etc/letsencrypt/live/$DJANGO_DOMAIN/fullchain.pem"
        SSL_KEY="/etc/letsencrypt/live/$DJANGO_DOMAIN/privkey.pem"
        echo "✅ Let's Encrypt SSL certificate configured"
    fi
else
    # Create self-signed certificate
    mkdir -p /etc/ssl/certs /etc/ssl/private
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/django.key \
        -out /etc/ssl/certs/django.crt \
        -subj "/C=US/ST=CA/L=San Francisco/O=Camlo Technologies/CN=$DJANGO_DOMAIN"
    
    SSL_CERT="/etc/ssl/certs/django.crt"
    SSL_KEY="/etc/ssl/private/django.key"
    echo "✅ Self-signed SSL certificate created"
fi

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/trading_dashboard << EOF
server {
    listen 80;
    server_name $DJANGO_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DJANGO_DOMAIN;

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

    # Static files
    location /static/ {
        alias $INSTALL_DIR/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias $INSTALL_DIR/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # WebSocket support for real-time updates
    location /ws/ {
        proxy_pass http://localhost:$DJANGO_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Main application
    location / {
        proxy_pass http://localhost:$DJANGO_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:$DJANGO_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/trading_dashboard /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t
if [[ $? -ne 0 ]]; then
    echo "❌ Nginx configuration test failed"
    exit 1
fi

echo "✅ Nginx configured"

# Create Django environment file
echo "⚙️  Creating Django environment configuration..."
cat > $INSTALL_DIR/.env << EOF
# Django Trading Dashboard Environment Configuration
DEBUG=False
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

# Database Configuration
DATABASE_URL=postgres://trading_dashboard_user:trading_dashboard_password_change_me@localhost/trading_dashboard_db

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Domain Configuration
ALLOWED_HOSTS=$DJANGO_DOMAIN,localhost,127.0.0.1
DJANGO_DOMAIN=$DJANGO_DOMAIN
DJANGO_PORT=$DJANGO_PORT

# Integration URLs
DODOHOOK_DOMAIN=$DODOHOOK_DOMAIN
DODOHOOK_API_URL=https://$DODOHOOK_DOMAIN/api
N8N_DOMAIN=$N8N_DOMAIN
N8N_API_URL=https://$N8N_DOMAIN/api

# API Keys (configure these)
ALPHA_VANTAGE_API_KEY=your_alpha_vantage_api_key
NEWS_API_KEY=your_news_api_key
TWITTER_BEARER_TOKEN=your_twitter_bearer_token

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=your_email_password

# Security
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Logging
LOG_LEVEL=INFO
SENTRY_DSN=your_sentry_dsn_if_using

# Celery Configuration
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
EOF

chown $DJANGO_USER:$DJANGO_USER $INSTALL_DIR/.env
chmod 600 $INSTALL_DIR/.env

echo "✅ Environment configuration created"

# Create systemd service for Django
echo "🔧 Creating Django systemd service..."
cat > /etc/systemd/system/trading_dashboard.service << EOF
[Unit]
Description=Django Trading Dashboard
After=network.target postgresql.service redis.service
Requires=postgresql.service redis.service

[Service]
Type=exec
User=$DJANGO_USER
WorkingDirectory=$INSTALL_DIR
Environment=DJANGO_SETTINGS_MODULE=$DJANGO_PROJECT.settings
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$VENV_PATH/bin/daphne -b 0.0.0.0 -p $DJANGO_PORT $DJANGO_PROJECT.asgi:application
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=strict
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

# Create Celery service for background tasks
cat > /etc/systemd/system/trading_dashboard_celery.service << EOF
[Unit]
Description=Django Trading Dashboard Celery Worker
After=network.target redis.service
Requires=redis.service

[Service]
Type=forking
User=$DJANGO_USER
WorkingDirectory=$INSTALL_DIR
Environment=DJANGO_SETTINGS_MODULE=$DJANGO_PROJECT.settings
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$VENV_PATH/bin/celery -A $DJANGO_PROJECT worker --detach --loglevel=info
ExecStop=$VENV_PATH/bin/celery -A $DJANGO_PROJECT control shutdown
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create Celery Beat service for scheduled tasks
cat > /etc/systemd/system/trading_dashboard_celerybeat.service << EOF
[Unit]
Description=Django Trading Dashboard Celery Beat
After=network.target redis.service
Requires=redis.service

[Service]
Type=simple
User=$DJANGO_USER
WorkingDirectory=$INSTALL_DIR
Environment=DJANGO_SETTINGS_MODULE=$DJANGO_PROJECT.settings
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$VENV_PATH/bin/celery -A $DJANGO_PROJECT beat --loglevel=info
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Systemd services created"

# Configure firewall
echo "🔥 Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp
ufw --force enable

echo "✅ Firewall configured"

# Create SSL renewal script
cat > /etc/cron.daily/renew-django-ssl << 'RENEWAL_EOF'
#!/bin/bash
# Renew SSL certificates for Django Trading Dashboard

certbot renew --quiet --no-self-upgrade
if [[ $? -eq 0 ]]; then
    systemctl reload nginx
    logger "Django Trading Dashboard SSL certificate renewed successfully"
fi
RENEWAL_EOF

chmod +x /etc/cron.daily/renew-django-ssl

# Set ownership
chown -R $DJANGO_USER:$DJANGO_USER $INSTALL_DIR

echo "✅ Installation script completed"

# Display completion information
echo ""
echo "🎉 Django Trading Dashboard Installation Complete!"
echo "================================================="
echo ""
echo "📊 Service Information:"
echo "  Dashboard URL: https://$DJANGO_DOMAIN"
echo "  Admin URL: https://$DJANGO_DOMAIN/admin/"
echo "  API URL: https://$DJANGO_DOMAIN/api/"
echo ""
echo "🔗 Integration URLs:"
echo "  DodoHook: https://$DODOHOOK_DOMAIN"
echo "  n8n: https://$N8N_DOMAIN"
echo ""
echo "📁 Installation Details:"
echo "  Install Directory: $INSTALL_DIR"
echo "  Virtual Environment: $VENV_PATH"
echo "  Configuration: $INSTALL_DIR/.env"
echo ""
echo "🎯 Next Steps:"
echo "  1. Configure Django settings: $INSTALL_DIR/$DJANGO_PROJECT/settings.py"
echo "  2. Create ML analytics app: cd $INSTALL_DIR && sudo -u $DJANGO_USER ./manage.py migrate"
echo "  3. Create superuser: cd $INSTALL_DIR && sudo -u $DJANGO_USER $VENV_PATH/bin/python manage.py createsuperuser"
echo "  4. Collect static files: cd $INSTALL_DIR && sudo -u $DJANGO_USER $VENV_PATH/bin/python manage.py collectstatic"
echo "  5. Start services: systemctl enable --now trading_dashboard trading_dashboard_celery trading_dashboard_celerybeat nginx"
echo ""
echo "📚 Documentation:"
echo "  Django Docs: https://docs.djangoproject.com/"
echo "  DRF Docs: https://www.django-rest-framework.org/"
echo ""
echo "⚠️  Important:"
echo "  - Update API keys in $INSTALL_DIR/.env"
echo "  - Change database password in production"
echo "  - Configure email settings for notifications"
echo ""
echo "✅ Ready to build your ML Trading Dashboard!"