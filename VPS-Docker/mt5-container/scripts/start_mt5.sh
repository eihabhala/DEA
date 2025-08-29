#!/bin/bash

# MetaTrader 5 Startup Script for Docker Container
# This script handles MT5 initialization, configuration, and startup

set -e

MT5_DIR="/home/mt5/.wine/drive_c/Program Files/MetaTrader 5"
CONFIG_DIR="/home/mt5/config"
LOG_DIR="/home/mt5/logs"

# Ensure we're running as the mt5 user
if [ "$(id -u)" -ne "$(id -u mt5 2>/dev/null || echo 1000)" ]; then
    echo "This script must be run as the mt5 user" >&2
    exit 1
fi

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/startup.log"
}

# Wait for X server
wait_for_x() {
    log "Waiting for X server..."
    while ! xdpyinfo -display :1 >/dev/null 2>&1; do
        sleep 1
    done
    log "X server is ready"
}

# Initialize Wine if not already done
init_wine() {
    log "Initializing Wine..."
    
    # Set Wine prefix
    export WINEPREFIX="/home/mt5/.wine"
    
    # Check if Wine is already initialized
    if [[ ! -d "$WINEPREFIX" ]]; then
        log "Creating Wine prefix..."
        winecfg /v win10
    else
        log "Wine prefix already exists"
    fi
    
    # Install core fonts if not already installed
    if [[ ! -f "$WINEPREFIX/drive_c/windows/Fonts/arial.ttf" ]]; then
        log "Installing core fonts..."
        winetricks -q corefonts
    else
        log "Core fonts already installed"
    fi
    
    # Install Visual C++ 2019 runtime if not already installed
    if ! wine reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall" | grep -q "Microsoft Visual C++ 2019"; then
        log "Installing Visual C++ 2019 runtime..."
        winetricks -q vcrun2019
    else
        log "Visual C++ 2019 runtime already installed"
    fi
}

# Configure MetaTrader 5
configure_mt5() {
    log "Configuring MetaTrader 5..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$MT5_DIR/config"
    
    # Copy EA files if they exist
    if [[ -d "/home/mt5/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Experts" ]]; then
        log "EA files found, copying to MT5 directory..."
        # EA files are already mounted, no need to copy
    fi
    
    # Create terminal configuration
    cat > "$MT5_DIR/config/terminal.ini" << EOF
[Common]
Login=${MT_LOGIN:-12345678}
Password=${MT_PASSWORD:-password}
Server=${MT_SERVER:-Demo-Server}
AutoLogin=true
EnableNews=false
EnableMail=false
EnableSignals=false
MaxBars=10000

[Charts]
ChartOnTop=false
PrintColor=false
SaveDeleted=true

[Expert]
AllowLive=true
AllowImport=true
AllowWebRequest=true
EOF

    log "MT5 configuration complete"
}

# Start MetaTrader 5
start_mt5() {
    log "Starting MetaTrader 5..."
    
    # Change to MT5 directory
    cd "$MT5_DIR"
    
    # Set display
    export DISPLAY=:1
    export WINEPREFIX="/home/mt5/.wine"
    
    # Start MT5 with Wine
    wine terminal64.exe /config:"$MT5_DIR/config/terminal.ini" /portable
}

# Main execution
main() {
    log "=== MetaTrader 5 Container Startup ==="
    
    # Wait for X server
    wait_for_x
    
    # Initialize Wine
    init_wine
    
    # Configure MT5
    configure_mt5
    
    # Start MT5
    start_mt5
}

# Run main function
main "$@"