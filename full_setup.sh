#!/bin/bash

# Full Setup Script for DEA (AI Trading Expert Advisor)
# This script configures the entire project for use

echo "🚀 Starting full setup for DEA (AI Trading Expert Advisor)"
echo "========================================================"

# Navigate to project root
cd /home/eboalking/DEA

# 1. Update repository to latest version
echo "🔄 Updating repository..."
git pull origin main

# 2. Install Python dependencies for Webhook Server
echo "🐍 Installing Python dependencies for Webhook Server..."
cd /home/eboalking/DEA/Webhook_Server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 3. Install Python dependencies for Custom Tunnel Server (DodoHook)
echo "🐦 Installing Python dependencies for DodoHook..."
pip install -r requirements_tunnel.txt

# 4. Install Python dependencies for Django Dashboard
echo "🌐 Installing Python dependencies for Django Dashboard..."
cd /home/eboalking/DEA/django-dashboard
pip install -r requirements.txt

# 5. Set up VPS-Docker environment
echo "🐳 Setting up VPS-Docker environment..."
cd /home/eboalking/DEA/VPS-Docker

# Create necessary directories
mkdir -p data/{mt4,mt5,webhook,backups} logs/{mt4,mt5,webhook,nginx} config/{mt4,mt5,webhook} nginx/ssl monitoring/{grafana,prometheus}

# Copy example environment file
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "📝 Created .env file from example. Please edit with your settings."
fi

# 6. Set up MT5 configuration
echo "⚙️ Setting up MT5 configuration..."
if [ ! -f "/home/eboalking/DEA/VPS-Docker/mt5-container/config/mt5-config.ini" ]; then
    mkdir -p /home/eboalking/DEA/VPS-Docker/mt5-container/config
    cat > /home/eboalking/DEA/VPS-Docker/mt5-container/config/mt5-config.ini << EOF
[Settings]
Server=Demo-Server
Login=12345678
Password=demopassword
EOF
    echo "📝 Created default MT5 configuration file."
fi

# 7. Make scripts executable
echo "🔧 Making scripts executable..."
find /home/eboalking/DEA -name "*.sh" -exec chmod +x {} \;

# 8. Verify Docker installation
echo "🐳 Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed"
    if command -v docker-compose &> /dev/null; then
        echo "✅ Docker Compose is installed"
    else
        echo "⚠️ Docker Compose is not installed. Please install it for full VPS functionality."
    fi
else
    echo "⚠️ Docker is not installed. Please install Docker for full VPS functionality."
fi

# 9. Display summary
echo ""
echo "✅ Full setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Edit /home/eboalking/DEA/VPS-Docker/.env with your settings"
echo "2. Configure MT4/MT5 broker settings in the config files"
echo "3. To start the webhook server: cd /home/eboalking/DEA/Webhook_Server && source venv/bin/activate && ./start_server.sh"
echo "4. To start VPS containers: cd /home/eboalking/DEA/VPS-Docker && docker-compose up -d"
echo "5. To start Django dashboard: cd /home/eboalking/DEA/django-dashboard && python manage.py runserver"
echo ""
echo "📖 Check documentation in /home/eboalking/DEA/Documentation/"
echo "📄 README: /home/eboalking/DEA/README.md"