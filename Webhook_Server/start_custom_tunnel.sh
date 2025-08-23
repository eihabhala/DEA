#!/bin/bash

# Custom Tunnel Server Startup Script
# This script starts your self-hosted webhook tunneling service

echo "🦤 Starting DodoHook - Professional Webhook Tunneling"
echo "by Camlo Technologies"
echo "==============================================="

# Change to the webhook server directory
cd "$(dirname "$0")"

# Check if configuration exists
if [ ! -f "tunnel_config.yaml" ]; then
    echo "❌ Configuration file not found!"
    echo "Please create tunnel_config.yaml first"
    exit 1
fi

# Check if Python dependencies are installed
echo "📦 Checking dependencies..."
python3 -c "import aiohttp, yaml" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📥 Installing required dependencies..."
    pip3 install aiohttp pyyaml
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        echo "Please run: pip3 install aiohttp pyyaml"
        exit 1
    fi
fi

echo "✅ Dependencies OK"

# Check SSL certificates
if [ ! -f "certs/server.crt" ] || [ ! -f "certs/server.key" ]; then
    echo "🔐 SSL certificates not found"
    echo "Do you want to generate self-signed certificates? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        ./generate_ssl.sh
    else
        echo "⚠️  Starting without SSL (HTTP only)"
        echo "Update tunnel_config.yaml to disable SSL or provide certificates"
    fi
fi

# Check if local webhook server is running
echo "🔍 Checking local webhook server..."
LOCAL_PORT=$(grep "local_port:" tunnel_config.yaml | awk '{print $2}')
if [ -z "$LOCAL_PORT" ]; then
    LOCAL_PORT=5000
fi

nc -z localhost $LOCAL_PORT 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️  Local webhook server not detected on port $LOCAL_PORT"
    echo "Starting local webhook server..."
    
    # Start local webhook server in background
    python3 webhook_server.py &
    LOCAL_PID=$!
    echo "📱 Local webhook server started (PID: $LOCAL_PID)"
    
    # Wait for it to start
    sleep 3
else
    echo "✅ Local webhook server is running"
fi

# Get configuration details
DOMAIN=$(grep "domain:" tunnel_config.yaml | awk '{print $2}')
PORT=$(grep "port:" tunnel_config.yaml | head -1 | awk '{print $2}')

if [ -z "$DOMAIN" ]; then
    DOMAIN="localhost"
fi

if [ -z "$PORT" ]; then
    PORT=443
fi

# Display configuration
echo ""
echo "🌐 Tunnel Configuration:"
echo "  Domain: $DOMAIN"
echo "  Port: $PORT"
echo "  Local Port: $LOCAL_PORT"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down tunnel server..."
    if [ ! -z "$LOCAL_PID" ]; then
        kill $LOCAL_PID 2>/dev/null
        echo "📱 Local webhook server stopped"
    fi
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT

# Start the custom tunnel server
echo "🚀 Starting custom tunnel server..."
echo ""
echo "📋 Access Points:"
echo "  Webhook URL: https://$DOMAIN/webhook"
echo "  Dashboard: https://$DOMAIN/dashboard"
echo "  Status API: https://$DOMAIN/status"
echo ""
echo "🔄 Press Ctrl+C to stop the server"
echo "================================================"

python3 custom_tunnel_server.py

echo ""
echo "✅ Tunnel server stopped"