#!/bin/bash

# Stop DEA-MT4 Script
# This script stops only the MetaTrader 4 container for the DEA trading system

echo "🛑 Stopping DEA-MT4 Container..."
echo "==============================="

# Navigate to the VPS-Docker directory
cd /home/eboalking/DEA/VPS-Docker

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running."
    exit 1
fi

echo "✅ Docker is running"

# Stop MetaTrader 4 Container
echo "🔄 Stopping MetaTrader 4 Container..."
docker compose --profile mt4 stop metatrader4

# Display MT4 container status
echo ""
echo "📊 MetaTrader 4 Container Status:"
echo "================================"
docker compose ps metatrader4

echo ""
echo "✅ DEA-MT4 Container Stopped Successfully!"
echo ""