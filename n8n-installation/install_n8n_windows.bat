@echo off
REM n8n Installation with DodoHook Integration (Windows)
REM by Camlo Technologies

title n8n Installation with DodoHook Integration

echo.
echo 🚀 n8n Installation with DodoHook Integration (Windows)
echo by Camlo Technologies
echo =====================================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Set configuration variables
set N8N_DOMAIN=%1
set N8N_PORT=%2
set WEBHOOK_DOMAIN=%3

if "%N8N_DOMAIN%"=="" set N8N_DOMAIN=n8n.yourtrading.com
if "%N8N_PORT%"=="" set N8N_PORT=5678
if "%WEBHOOK_DOMAIN%"=="" set WEBHOOK_DOMAIN=webhook.dodohook.com

echo 📋 Configuration:
echo   n8n Domain: %N8N_DOMAIN%
echo   n8n Port: %N8N_PORT%
echo   DodoHook Domain: %WEBHOOK_DOMAIN%
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed
    echo.
    echo Please install Node.js first:
    echo 1. Go to https://nodejs.org/
    echo 2. Download and install the latest LTS version
    echo 3. Restart this script
    echo.
    pause
    exit /b 1
)

REM Display Node.js version
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo ✅ Node.js installed: %NODE_VERSION%
echo ✅ npm installed: %NPM_VERSION%
echo.

REM Install n8n globally
echo 🔧 Installing n8n...
npm install -g n8n
if %errorlevel% neq 0 (
    echo ❌ Failed to install n8n
    pause
    exit /b 1
)
echo ✅ n8n installed successfully
echo.

REM Create n8n data directory
set N8N_DATA_DIR=%USERPROFILE%\.n8n
if not exist "%N8N_DATA_DIR%" (
    mkdir "%N8N_DATA_DIR%"
    echo ✅ Created n8n data directory: %N8N_DATA_DIR%
)

REM Create n8n configuration
echo ⚙️ Creating n8n configuration...
set N8N_CONFIG_FILE=%N8N_DATA_DIR%\config.json

echo { > "%N8N_CONFIG_FILE%"
echo   "host": "0.0.0.0", >> "%N8N_CONFIG_FILE%"
echo   "port": %N8N_PORT%, >> "%N8N_CONFIG_FILE%"
echo   "protocol": "http", >> "%N8N_CONFIG_FILE%"
echo   "editorBaseUrl": "http://localhost:%N8N_PORT%", >> "%N8N_CONFIG_FILE%"
echo   "webhookUrl": "http://localhost:%N8N_PORT%", >> "%N8N_CONFIG_FILE%"
echo   "payloadSizeMax": 16, >> "%N8N_CONFIG_FILE%"
echo   "secureCookie": false, >> "%N8N_CONFIG_FILE%"
echo   "timezone": "UTC" >> "%N8N_CONFIG_FILE%"
echo } >> "%N8N_CONFIG_FILE%"

echo ✅ Configuration created: %N8N_CONFIG_FILE%
echo.

REM Create DodoHook integration batch file
echo 🔗 Creating DodoHook integration script...
set DODOHOOK_SCRIPT=%N8N_DATA_DIR%\setup_dodohook_integration.bat

echo @echo off > "%DODOHOOK_SCRIPT%"
echo. >> "%DODOHOOK_SCRIPT%"
echo echo 🔗 DodoHook Integration Setup for n8n >> "%DODOHOOK_SCRIPT%"
echo echo ========================================== >> "%DODOHOOK_SCRIPT%"
echo echo. >> "%DODOHOOK_SCRIPT%"
echo echo 📋 DodoHook Webhook URLs for n8n: >> "%DODOHOOK_SCRIPT%"
echo echo   Main endpoint: https://%WEBHOOK_DOMAIN%/webhook/n8n >> "%DODOHOOK_SCRIPT%"
echo echo   Workflow-specific: https://%WEBHOOK_DOMAIN%/webhook/n8n/{workflow-id} >> "%DODOHOOK_SCRIPT%"
echo echo. >> "%DODOHOOK_SCRIPT%"
echo echo 📝 Example n8n Webhook Configuration: >> "%DODOHOOK_SCRIPT%"
echo echo   1. Add a 'Webhook' node to your workflow >> "%DODOHOOK_SCRIPT%"
echo echo   2. Set HTTP Method: POST >> "%DODOHOOK_SCRIPT%"
echo echo   3. Set Path: /webhook (n8n will generate full URL) >> "%DODOHOOK_SCRIPT%"
echo echo   4. Configure response: JSON >> "%DODOHOOK_SCRIPT%"
echo echo. >> "%DODOHOOK_SCRIPT%"
echo echo 🎯 Trading Signal Example: >> "%DODOHOOK_SCRIPT%"
echo echo   TradingView -^> DodoHook -^> n8n -^> Trading Platform >> "%DODOHOOK_SCRIPT%"
echo echo. >> "%DODOHOOK_SCRIPT%"
echo echo ✅ DodoHook integration guide created >> "%DODOHOOK_SCRIPT%"
echo echo 📚 For more examples, check: >> "%DODOHOOK_SCRIPT%"
echo echo    https://github.com/xnox-me/DEA/blob/main/Webhook_Server/N8N_INTEGRATION_GUIDE.md >> "%DODOHOOK_SCRIPT%"
echo echo. >> "%DODOHOOK_SCRIPT%"
echo pause >> "%DODOHOOK_SCRIPT%"

echo ✅ DodoHook integration script created: %DODOHOOK_SCRIPT%
echo.

REM Create startup script
echo 🚀 Creating n8n startup script...
set STARTUP_SCRIPT=%N8N_DATA_DIR%\start_n8n.bat

echo @echo off > "%STARTUP_SCRIPT%"
echo title n8n - Workflow Automation >> "%STARTUP_SCRIPT%"
echo echo. >> "%STARTUP_SCRIPT%"
echo echo 🚀 Starting n8n with DodoHook Integration >> "%STARTUP_SCRIPT%"
echo echo by Camlo Technologies >> "%STARTUP_SCRIPT%"
echo echo ============================================ >> "%STARTUP_SCRIPT%"
echo echo. >> "%STARTUP_SCRIPT%"
echo echo 📊 Configuration: >> "%STARTUP_SCRIPT%"
echo echo   Port: %N8N_PORT% >> "%STARTUP_SCRIPT%"
echo echo   Data Directory: %N8N_DATA_DIR% >> "%STARTUP_SCRIPT%"
echo echo   DodoHook Domain: %WEBHOOK_DOMAIN% >> "%STARTUP_SCRIPT%"
echo echo. >> "%STARTUP_SCRIPT%"
echo echo 🌐 Access URLs: >> "%STARTUP_SCRIPT%"
echo echo   n8n Interface: http://localhost:%N8N_PORT% >> "%STARTUP_SCRIPT%"
echo echo   DodoHook Webhook: https://%WEBHOOK_DOMAIN%/webhook/n8n >> "%STARTUP_SCRIPT%"
echo echo. >> "%STARTUP_SCRIPT%"
echo echo 🔄 Starting n8n... >> "%STARTUP_SCRIPT%"
echo echo Press Ctrl+C to stop >> "%STARTUP_SCRIPT%"
echo echo. >> "%STARTUP_SCRIPT%"
echo cd /d "%N8N_DATA_DIR%" >> "%STARTUP_SCRIPT%"
echo n8n start >> "%STARTUP_SCRIPT%"

echo ✅ Startup script created: %STARTUP_SCRIPT%
echo.

REM Configure Windows Firewall (if needed)
echo 🔥 Configuring Windows Firewall...
netsh advfirewall firewall show rule name="n8n" >nul 2>&1
if %errorlevel% neq 0 (
    netsh advfirewall firewall add rule name="n8n" dir=in action=allow protocol=TCP localport=%N8N_PORT%
    echo ✅ Firewall rule added for port %N8N_PORT%
) else (
    echo ✅ Firewall rule already exists for n8n
)
echo.

REM Create Windows Service (optional)
echo 📋 Windows Service Setup (Optional)
echo.
echo To run n8n as a Windows Service, you can use:
echo 1. NSSM (Non-Sucking Service Manager)
echo 2. PM2 with pm2-windows-service
echo.
echo Manual setup with NSSM:
echo 1. Download NSSM from https://nssm.cc/download
echo 2. Run: nssm install n8n
echo 3. Set Application path: %~dp0start_n8n.bat
echo 4. Start service: nssm start n8n
echo.

REM Display completion information
echo.
echo 🎉 n8n Installation Complete!
echo =============================
echo.
echo 📊 Installation Summary:
echo   n8n Version: Installed globally
echo   Configuration: %N8N_CONFIG_FILE%
echo   Data Directory: %N8N_DATA_DIR%
echo   Startup Script: %STARTUP_SCRIPT%
echo.
echo 🔗 DodoHook Integration:
echo   Webhook URLs: https://%WEBHOOK_DOMAIN%/webhook/n8n
echo   Integration Script: %DODOHOOK_SCRIPT%
echo.
echo 🚀 Starting n8n:
echo   Quick Start: "%STARTUP_SCRIPT%"
echo   Manual Start: n8n start
echo   Web Interface: http://localhost:%N8N_PORT%
echo.
echo 🔧 Management:
echo   Stop n8n: Press Ctrl+C in the n8n window
echo   Restart: Close and run startup script again
echo   Configuration: Edit %N8N_CONFIG_FILE%
echo.
echo 🎯 Next Steps:
echo   1. Run: "%STARTUP_SCRIPT%"
echo   2. Open: http://localhost:%N8N_PORT%
echo   3. Complete n8n initial setup
echo   4. Run: "%DODOHOOK_SCRIPT%"
echo   5. Create workflows with DodoHook integration
echo.
echo 📚 Documentation:
echo   n8n Docs: https://docs.n8n.io
echo   DodoHook Guide: https://github.com/xnox-me/DEA/blob/main/Webhook_Server/N8N_INTEGRATION_GUIDE.md
echo.

REM Ask if user wants to start n8n now
echo 🚀 Would you like to start n8n now? (Y/N)
set /p START_NOW=
if /i "%START_NOW%"=="Y" (
    echo.
    echo Starting n8n...
    call "%STARTUP_SCRIPT%"
) else (
    echo.
    echo ✅ Installation completed successfully!
    echo Run "%STARTUP_SCRIPT%" when ready to start n8n
)

echo.
pause