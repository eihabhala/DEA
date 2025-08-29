#!/bin/bash

# Start All Trading Services Script
# This script starts all the necessary services for the DEA trading system

echo "🚀 Starting DEA Trading System Services..."
echo "========================================"

# Navigate to the VPS-Docker directory
cd /home/eboalking/DEA/VPS-Docker

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Start Redis service (required for all other services)
echo "🔄 Starting Redis service..."
docker compose up -d redis
sleep 5

# Check if Redis is running
if docker ps | grep -q "dea-redis"; then
    echo "✅ Redis service started successfully"
else
    echo "❌ Failed to start Redis service"
    exit 1
fi

# Start Webhook Server
echo "🔄 Starting Webhook Server..."
docker compose up -d webhook-server
sleep 10

# Check if Webhook Server is running
if docker ps | grep -q "dea-webhook-server"; then
    echo "✅ Webhook Server started successfully"
else
    echo "❌ Failed to start Webhook Server"
    exit 1
fi

# Start Monitoring Services
echo "🔄 Starting Monitoring Services..."
docker compose --profile monitoring up -d grafana prometheus
sleep 10

# Check if Monitoring Services are running
if docker ps | grep -q "dea-grafana" && docker ps | grep -q "dea-prometheus"; then
    echo "✅ Monitoring Services started successfully"
else
    echo "❌ Failed to start Monitoring Services"
    exit 1
fi

# Start Database Service
echo "🔄 Starting Database Service..."
docker compose --profile database up -d postgres
sleep 10

# Check if Database Service is running
if docker ps | grep -q "dea-postgres"; then
    echo "✅ Database Service started successfully"
else
    echo "❌ Failed to start Database Service"
    exit 1
fi

# Start MetaTrader 5 (default platform)
echo "🔄 Starting MetaTrader 5 Container..."
docker compose --profile mt5 up -d metatrader5
sleep 15

# Check if MetaTrader 5 is running
if docker ps | grep -q "dea-mt5"; then
    echo "✅ MetaTrader 5 Container started successfully"
else
    echo "❌ Failed to start MetaTrader 5 Container"
    exit 1
fi

# Display service status
echo ""
echo "📊 Service Status:"
echo "=================="
docker compose ps

# Display connection information
echo ""
echo "🔗 Connection Information:"
echo "========================="
echo "Webhook Server: http://localhost:5000"
echo "Health Check: http://localhost:5000/health"
echo "Status Endpoint: http://localhost:5000/status"
echo "Grafana Dashboard: http://localhost:3000 (admin/admin123)"
echo "Prometheus Metrics: http://localhost:9090"
echo "PostgreSQL Database: localhost:5432"
echo "Redis Cache: localhost:6379"
echo "MetaTrader 5 VNC: localhost:5902 (password: trading123)"
echo ""

echo "🎉 All DEA Trading System Services Started Successfully!"
echo "💡 Next steps:"
echo "   1. Connect to MT5 via VNC to configure your broker settings"
echo "   2. Attach the EA to a chart in MetaTrader"
echo "   3. Send test signals to http://localhost:5000/webhook"
echo ""