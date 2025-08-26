#!/bin/bash

# Simplified DEA Repository Checker
# This script checks the DEA repository for common issues

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORK_DIR="/home/eboalking/DEA"
LOG_FILE="/home/eboalking/DEA/repository-check.log"
ERROR_LOG="/home/eboalking/DEA/repository-errors.log"

# Initialize log files
echo "=== DEA Repository Checker Log - $(date) ===" > "$LOG_FILE"
echo "=== DEA Repository Errors Log - $(date) ===" > "$ERROR_LOG"

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to log errors
log_error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
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

# Function to check repository health
check_repo_health() {
    local repo_path="$WORK_DIR"
    
    log_info "Checking DEA repository health..."
    
    cd "$repo_path"
    
    # Initialize error counter
    local error_count=0
    
    # 1. Check git status
    log_info "  Checking git status..."
    if ! git status >/dev/null 2>&1; then
        log_error "  Failed to get git status"
        ((error_count++))
    else
        local uncommitted=$(git status --porcelain | wc -l)
        if [ "$uncommitted" -gt 0 ]; then
            log_warning "  Repository has $uncommitted uncommitted changes"
        fi
    fi
    
    # 2. Check for README.md
    log_info "  Checking for README.md..."
    if [ ! -f "README.md" ]; then
        log_error "  Missing README.md file"
        ((error_count++))
    fi
    
    # 3. Check for LICENSE
    log_info "  Checking for LICENSE..."
    if [ ! -f "LICENSE" ]; then
        log_warning "  Missing LICENSE file"
    fi
    
    # 4. Check for broken links in README (basic check)
    log_info "  Checking for broken links in README..."
    if [ -f "README.md" ]; then
        # Check for common broken link patterns
        if grep -i "yourusername" "README.md" >/dev/null 2>&1; then
            log_error "  README.md has placeholder 'yourusername'"
            ((error_count++))
        fi
        
        # Check for xnox-me references
        if ! grep -i "xnox-me" "README.md" >/dev/null 2>&1; then
            log_warning "  README.md may be missing xnox-me references"
        fi
    fi
    
    # 5. Check for TODO comments in code
    log_info "  Checking for TODO comments..."
    local todo_count=$(grep -r "TODO" --include="*.py" --include="*.js" --include="*.java" --include="*.cpp" --include="*.c" --include="*.h" --include="*.sh" . 2>/dev/null | wc -l)
    if [ "$todo_count" -gt 0 ]; then
        log_warning "  Repository has $todo_count TODO comments"
    fi
    
    # 6. Check for large files (>10MB)
    log_info "  Checking for large files..."
    local large_files=$(find . -type f -size +10M ! -path "./.git/*" 2>/dev/null | wc -l)
    if [ "$large_files" -gt 0 ]; then
        log_warning "  Repository has $large_files large files (>10MB)"
    fi
    
    # 7. Check setup scripts for placeholder URLs
    log_info "  Checking setup scripts..."
    if [ -f "setup_repository.sh" ]; then
        if grep -i "yourusername" "setup_repository.sh" >/dev/null 2>&1; then
            log_error "  setup_repository.sh has placeholder 'yourusername'"
            ((error_count++))
        fi
        if ! grep -i "xnox-me" "setup_repository.sh" >/dev/null 2>&1; then
            log_warning "  setup_repository.sh may be missing xnox-me references"
        fi
    fi
    
    if [ -f "setup_repository.bat" ]; then
        if grep -i "yourusername" "setup_repository.bat" >/dev/null 2>&1; then
            log_error "  setup_repository.bat has placeholder 'yourusername'"
            ((error_count++))
        fi
        if ! grep -i "xnox-me" "setup_repository.bat" >/dev/null 2>&1; then
            log_warning "  setup_repository.bat may be missing xnox-me references"
        fi
    fi
    
    # 8. Check for common documentation issues we've already fixed
    log_info "  Checking for previously fixed issues..."
    
    # Check if we still have the fixes we applied
    if [ -f "DOCUMENTATION_FIXES_APPLIED.md" ]; then
        log_success "  Documentation fixes have been applied"
    else
        log_warning "  Documentation fixes summary missing"
    fi
    
    # 9. Check for management scripts
    log_info "  Checking for management scripts..."
    if [ -f "xnox-repo-checker.sh" ] && [ -f "xnox-update-all.sh" ] && [ -f "xnox-manage.sh" ]; then
        log_success "  Repository management scripts present"
    else
        log_warning "  Some repository management scripts missing"
    fi
    
    # Summary
    if [ "$error_count" -eq 0 ]; then
        log_success "  Repository passed all critical checks"
    else
        log_error "  Repository has $error_count critical issues"
    fi
    
    return $error_count
}

# Main function
main() {
    log_message "Starting DEA Repository Health Check"
    log_message "Working directory: $WORK_DIR"
    log_message "=================================================="
    
    # Check if we're in the right directory
    if [ ! -d "$WORK_DIR" ] || [ ! -f "$WORK_DIR/README.md" ]; then
        log_error "DEA repository not found at $WORK_DIR"
        exit 1
    fi
    
    # Check repository health
    if check_repo_health; then
        log_success "Repository health check completed successfully!"
    else
        log_warning "Repository health check completed with issues."
    fi
    
    log_message "=================================================="
    log_message "Logs saved to: $LOG_FILE"
    log_message "Errors saved to: $ERROR_LOG"
    log_message "Completed at: $(date)"
}

# Run main function
main "$@"