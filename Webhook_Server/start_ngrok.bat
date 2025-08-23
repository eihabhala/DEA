@echo off
REM Ngrok Setup for TradingView Webhooks (Windows)

title TradingView Webhook Setup

echo.
echo 🌐 Setting up Public Webhook URL for TradingView
echo ===============================================
echo.

REM Check if ngrok is installed
ngrok version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ngrok is not installed.
    echo.
    echo Please install ngrok:
    echo 1. Go to https://ngrok.com/download
    echo 2. Download and install ngrok for Windows
    echo 3. Sign up for free account at https://dashboard.ngrok.com/signup
    echo 4. Get your auth token from https://dashboard.ngrok.com/get-started/your-authtoken
    echo 5. Run: ngrok config add-authtoken YOUR_TOKEN
    echo.
    pause
    exit /b 1
)

echo ✅ ngrok found

REM Check if webhook server is ready
if not exist "webhook_server.py" (
    echo ❌ webhook_server.py not found
    echo Please run this script from the Webhook_Server directory
    pause
    exit /b 1
)

echo ✅ webhook_server.py found

REM Start the webhook server in background
echo 🚀 Starting webhook server on port 5000...
start /B python webhook_server.py

REM Wait a moment for server to start
timeout /t 3 /nobreak >nul

REM Start ngrok tunnel
echo 🌐 Creating public tunnel with ngrok...
start /B ngrok http 5000

REM Wait for ngrok to establish tunnel
timeout /t 5 /nobreak >nul

echo.
echo 🎯 Getting your public webhook URL...
echo.
echo 📋 To get your webhook URL:
echo    1. Open http://localhost:4040 in your browser
echo    2. Copy the HTTPS URL (not HTTP)
echo    3. Add '/webhook' to the end
echo    4. Use that as your TradingView webhook URL
echo.
echo 📝 TradingView Setup:
echo    1. Go to TradingView alerts
echo    2. Set webhook URL to: YOUR_NGROK_URL/webhook
echo    3. Use this JSON message format:
echo    {"action":"{{strategy.order.action}}","symbol":"{{ticker}}","price":"{{close}}"}
echo.
echo 🔄 Keep ngrok running to maintain the tunnel!
echo    Close the ngrok window to stop the tunnel
echo.

REM Open ngrok dashboard
start http://localhost:4040

echo Press any key to exit this setup script...
echo (Keep ngrok running in its own window)
pause >nul