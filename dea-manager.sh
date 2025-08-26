#!/bin/bash

# DEA Repository Manager
# This script provides a unified interface for managing the DEA repository

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORK_DIR="/home/eboalking/DEA"

# Function to display usage
usage() {
    echo "DEA Repository Manager"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  update    Update the repository with latest changes"
    echo "  check     Check the repository for issues"
    echo "  both      Update and then check the repository"
    echo "  status    Show repository status"
    echo "  help      Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 update"
    echo "  $0 check"
    echo "  $0 both"
}

# Function to log messages
log_message() {
    echo -e "$1"
}

# Function to log errors
log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to log success
log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Function to log warning
log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Function to log info
log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Function to update the repository
update_repo() {
    log_info "Updating DEA repository..."
    
    # Check if the updater script exists
    if [ -f "./dea-updater.sh" ]; then
        bash ./dea-updater.sh
    else
        log_error "Updater script not found!"
        return 1
    fi
}

# Function to check the repository
check_repo() {
    log_info "Checking DEA repository..."
    
    # Check if the checker script exists
    if [ -f "./dea-checker.sh" ]; then
        bash ./dea-checker.sh
    else
        log_error "Checker script not found!"
        return 1
    fi
}

# Function to show repository status
show_status() {
    log_info "Showing DEA repository status..."
    
    if [ -d "$WORK_DIR" ] && [ -d "$WORK_DIR/.git" ]; then
        cd "$WORK_DIR"
        echo "=== Repository Status ==="
        git status
        echo ""
        echo "=== Recent Commits ==="
        git log --oneline -5
        echo ""
        echo "=== Uncommitted Changes ==="
        git diff --stat
    else
        log_error "DEA repository not found at $WORK_DIR"
        return 1
    fi
}

# Function to update and check
update_and_check() {
    log_info "Updating and checking DEA repository..."
    
    # First update
    update_repo
    
    # Then check
    check_repo
}

# Main function
main() {
    # Make sure we have at least one argument
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    # Process command
    case "$1" in
        update)
            update_repo
            ;;
        check)
            check_repo
            ;;
        both)
            update_and_check
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"