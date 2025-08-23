#!/bin/bash

# Ngrok Setup for TradingView Webhooks
# This script sets up ngrok to expose your webhook server publicly

echo "🌐 Setting up Public Webhook URL for TradingView"
echo "==============================================="

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok is not installed."
    echo ""
    echo "Please install ngrok:"
    echo "1. Go to https://ngrok.com/download"
    echo "2. Download and install ngrok"
    echo "3. Sign up for free account at https://dashboard.ngrok.com/signup"
    echo "4. Get your auth token from https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "5. Run: ngrok config add-authtoken YOUR_TOKEN"
    echo ""
    exit 1
fi

echo "✅ ngrok found"

# Check if webhook server is ready
if [ ! -f "webhook_server.py" ]; then
    echo "❌ webhook_server.py not found"
    echo "Please run this script from the Webhook_Server directory"
    exit 1
fi

echo "✅ webhook_server.py found"

# Start the webhook server in background
echo "🚀 Starting webhook server on port 5000..."
python webhook_server.py &
WEBHOOK_PID=$!

# Wait a moment for server to start
sleep 3

# Start ngrok tunnel
echo "🌐 Creating public tunnel with ngrok..."
ngrok http 5000 &
NGROK_PID=$!

# Wait for ngrok to establish tunnel
sleep 5

# Get the public URL
echo ""
echo "🎯 Getting your public webhook URL..."
echo ""

# Try to get ngrok URL
if command -v curl &> /dev/null; then
    PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data['tunnels']:
        if tunnel['proto'] == 'https':
            print(tunnel['public_url'])
            break
except:
    print('Error getting URL')
")
    
    if [ ! -z "$PUBLIC_URL" ] && [ "$PUBLIC_URL" != "Error getting URL" ]; then
        echo "✅ Your Public Webhook URL:"
        echo "   $PUBLIC_URL/webhook"
        echo ""
        echo "📋 TradingView Setup:"
        echo "   1. Go to TradingView alerts"
        echo "   2. Set webhook URL to: $PUBLIC_URL/webhook"
        echo "   3. Use this JSON message format:"
        echo '   {"action":"{{strategy.order.action}}","symbol":"{{ticker}}","price":"{{close}}"}'
        echo ""
        echo "🔄 Keep this terminal open to maintain the tunnel!"
        echo "   Press Ctrl+C to stop the tunnel and webhook server"
        echo ""
    else
        echo "❌ Could not retrieve ngrok URL automatically"
        echo "📋 Manual steps:"
        echo "   1. Open http://localhost:4040 in your browser"
        echo "   2. Copy the HTTPS URL (not HTTP)"
        echo "   3. Add '/webhook' to the end"
        echo "   4. Use that as your TradingView webhook URL"
    fi
else
    echo "📋 Manual steps to get your webhook URL:"
    echo "   1. Open http://localhost:4040 in your browser"
    echo "   2. Copy the HTTPS URL (not HTTP)"
    echo "   3. Add '/webhook' to the end"
    echo "   4. Use that as your TradingView webhook URL"
fi

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $WEBHOOK_PID 2>/dev/null
    kill $NGROK_PID 2>/dev/null
    echo "✅ Cleanup complete"
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT

# Wait for user to stop
echo "Press Ctrl+C to stop the tunnel and webhook server"
wait