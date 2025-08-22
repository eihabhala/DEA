@echo off
REM ============================================================================
REM AI Trading Expert Advisor - Webhook Server Launcher
REM Copyright 2024, AI Trading Team
REM ============================================================================

title AI Trading Expert - Webhook Server

echo.
echo ============================================================================
echo                   AI TRADING EXPERT ADVISOR
echo                      Webhook Server Launcher
echo ============================================================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8 or later from https://python.org
    echo.
    pause
    exit /b 1
)

echo Python installation found.
echo.

REM Check if we're in the correct directory
if not exist "webhook_server.py" (
    echo ERROR: webhook_server.py not found in current directory
    echo Please run this script from the Webhook_Server directory
    echo.
    pause
    exit /b 1
)

REM Check if requirements are installed
echo Checking Python dependencies...
pip show flask >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing required dependencies...
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install dependencies
        echo Please run: pip install -r requirements.txt
        echo.
        pause
        exit /b 1
    )
) else (
    echo Dependencies are already installed.
)

echo.
echo Starting webhook server...
echo.
echo Server will be available at: http://localhost:8080
echo TradingView webhook URL: http://your-ip:8080/webhook
echo Server status: http://localhost:8080/status
echo.
echo Press Ctrl+C to stop the server
echo ============================================================================
echo.

REM Start the webhook server
python webhook_server.py

echo.
echo Webhook server has stopped.
pause