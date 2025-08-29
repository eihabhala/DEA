#!/bin/bash

# MetaTrader 4 Startup Script for Docker Container
# This script handles MT4 initialization, configuration, and startup

set -e

MT4_DIR="/home/mt4/.wine/drive_c/Program Files (x86)/MetaTrader 4"
CONFIG_DIR="/home/mt4/config"
LOG_DIR="/home/mt4/logs"

# Ensure we're running as the mt4 user
if [ "$(id -u)" -ne "$(id -u mt4 2>/dev/null || echo 1000)" ]; then
    echo "This script must be run as the mt4 user" >&2
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

# Create VNC password file
create_vnc_password() {
    log "Creating VNC password file..."
    
    # Create VNC directory if it doesn't exist
    mkdir -p /home/mt4/.vnc
    
    # Create VNC password file
    echo "trading123" | vncpasswd -f > /home/mt4/.vnc/passwd
    chmod 600 /home/mt4/.vnc/passwd
}

# Configure MetaTrader 4
configure_mt4() {
    log "Configuring MetaTrader 4..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$MT4_DIR/config"
    
    # Copy EA files if they exist
    if [[ -d "/home/mt4/.wine/drive_c/Program Files (x86)/MetaTrader 4/MQL4/Experts" ]]; then
        log "EA files found, copying to MT4 directory..."
        # EA files are already mounted, no need to copy
    fi
    
    # Create terminal configuration
    cat > "$MT4_DIR/config/terminal.ini" << EOF
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

    log "MT4 configuration complete"
}

# Start MetaTrader 4
start_mt4() {
    log "Starting MetaTrader 4..."
    
    # Change to MT4 directory
    cd "$MT4_DIR"
    
    # Set display
    export DISPLAY=:1
    
    # Start MT4 with Wine
    wine terminal.exe /config:"$MT4_DIR/config/terminal.ini" /portable
}

# Main execution
main() {
    log "=== MetaTrader 4 Container Startup ==="
    
    # Wait for X server
    wait_for_x
    
    # Create VNC password
    create_vnc_password
    
    # Configure MT4
    configure_mt4
    
    # Start MT4
    start_mt4
}

# Run main function
main "$@"