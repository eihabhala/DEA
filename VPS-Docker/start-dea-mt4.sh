#!/bin/bash

# Start DEA-MT4 Script
# This script starts only the MetaTrader 4 container for the DEA trading system

echo "🚀 Starting DEA-MT4 Container..."
echo "==============================="

# Navigate to the VPS-Docker directory
cd /home/eboalking/DEA/VPS-Docker

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Check if required services are already running
echo "🔍 Checking required services..."

# Check if Redis is running
if ! docker ps | grep -q "dea-redis"; then
    echo "🔄 Starting Redis service (required dependency)..."
    docker compose up -d redis
    sleep 5
    
    if docker ps | grep -q "dea-redis"; then
        echo "✅ Redis service started successfully"
    else
        echo "❌ Failed to start Redis service"
        exit 1
    fi
else
    echo "✅ Redis service is already running"
fi

# Check if Webhook Server is running
if ! docker ps | grep -q "dea-webhook-server"; then
    echo "🔄 Starting Webhook Server (required dependency)..."
    docker compose up -d webhook-server
    sleep 10
    
    if docker ps | grep -q "dea-webhook-server"; then
        echo "✅ Webhook Server started successfully"
    else
        echo "❌ Failed to start Webhook Server"
        exit 1
    fi
else
    echo "✅ Webhook Server is already running"
fi

# Start MetaTrader 4 Container
echo "🔄 Starting MetaTrader 4 Container..."
docker compose --profile mt4 up -d metatrader4
sleep 15

# Check if MetaTrader 4 is running
if docker ps | grep -q "dea-mt4"; then
    echo "✅ MetaTrader 4 Container started successfully"
else
    echo "❌ Failed to start MetaTrader 4 Container"
    exit 1
fi

# Display MT4 container status
echo ""
echo "📊 MetaTrader 4 Container Status:"
echo "================================"
docker compose ps metatrader4

# Display connection information
echo ""
echo "🔗 Connection Information:"
echo "========================="
echo "MetaTrader 4 VNC: localhost:5901 (password: trading123)"
echo "Webhook Server: http://localhost:5000"
echo "Health Check: http://localhost:5000/health"
echo ""

echo "🎉 DEA-MT4 Container Started Successfully!"
echo "💡 Next steps:"
echo "   1. Connect to MT4 via VNC to configure your broker settings"
echo "   2. Attach the EA to a chart in MetaTrader"
echo "   3. Send test signals to http://localhost:5000/webhook"
echo ""