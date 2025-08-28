#!/bin/bash

# Stop DEA-MT5 Script
# This script stops only the MetaTrader 5 container for the DEA trading system

echo "🛑 Stopping DEA-MT5 Container..."
echo "==============================="

# Navigate to the VPS-Docker directory
cd /home/eboalking/DEA/VPS-Docker

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running."
    exit 1
fi

echo "✅ Docker is running"

# Stop MetaTrader 5 Container
echo "🔄 Stopping MetaTrader 5 Container..."
docker compose --profile mt5 stop metatrader5

# Display MT5 container status
echo ""
echo "📊 MetaTrader 5 Container Status:"
echo "================================"
docker compose ps metatrader5

echo ""
echo "✅ DEA-MT5 Container Stopped Successfully!"
echo ""