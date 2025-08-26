#!/bin/bash

# Simple DEA Repository Updater
# This script updates the DEA repository with the latest changes

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORK_DIR="/home/eboalking/DEA"
LOG_FILE="/home/eboalking/DEA/update.log"

# Initialize log file
echo "=== DEA Repository Update Log - $(date) ===" > "$LOG_FILE"

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to log success
log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to log warning
log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to log info
log_info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Main function
main() {
    log_message "Starting DEA Repository Update"
    log_message "Working directory: $WORK_DIR"
    log_message "=================================================="
    
    # Check if we're in the right directory
    if [ ! -d "$WORK_DIR" ] || [ ! -d "$WORK_DIR/.git" ]; then
        log_message "ERROR: DEA repository not found at $WORK_DIR"
        exit 1
    fi
    
    cd "$WORK_DIR"
    
    # Check current status
    log_info "Checking current repository status..."
    git status
    
    # Fetch latest changes
    log_info "Fetching latest changes from remote..."
    if git fetch origin; then
        log_success "Successfully fetched changes"
    else
        log_warning "Failed to fetch changes"
        exit 1
    fi
    
    # Check if we're behind
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        log_success "Repository is up to date"
    else
        log_info "Repository is behind remote, pulling changes..."
        if git pull origin main; then
            log_success "Successfully updated repository"
        else
            log_warning "Failed to pull changes"
            exit 1
        fi
    fi
    
    # Show final status
    log_info "Final repository status:"
    git status --porcelain
    
    log_success "Repository update completed!"
    log_message "=================================================="
    log_message "Log saved to: $LOG_FILE"
    log_message "Completed at: $(date)"
}

# Run main function
main "$@"