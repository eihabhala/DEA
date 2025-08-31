#!/bin/bash

# ============================================================================
# AI Trading Expert Advisor - Webhook Server Launcher
# Copyright 2024, AI Trading Team
# ============================================================================

echo
echo "============================================================================"
echo "                   AI TRADING EXPERT ADVISOR"
echo "                      Webhook Server Launcher"
echo "============================================================================"
echo

# Check if we're in the correct directory
if [ ! -f "webhook_server.py" ]; then
    echo "ERROR: webhook_server.py not found in current directory"
    echo "Please run this script from the Webhook_Server directory"
    echo
    exit 1
fi

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Check if requirements are installed
echo "Checking Python dependencies..."
if ! python -c "import flask" 2>/dev/null; then
    echo "Installing required dependencies..."
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install dependencies"
        echo "Please run: pip install -r requirements.txt"
        echo
        exit 1
    fi
else
    echo "Dependencies are already installed."
fi

echo
echo "Starting webhook server..."
echo
echo "Server will be available at: http://localhost:5000"
echo "TradingView webhook URL: http://your-ip:5000/webhook"
echo "Server status: http://localhost:5000/status"
echo
echo "Press Ctrl+C to stop the server"
echo "============================================================================"
echo

# Start the webhook server
python webhook_server.py

echo
echo "Webhook server has stopped."