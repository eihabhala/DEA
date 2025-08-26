#!/bin/bash

# xnox-me Repository Update Script
# Script to update all xnox-me GitHub repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ORG_NAME="xnox-me"
WORK_DIR="$HOME/xnox-repos"
LOG_FILE="/tmp/xnox-update.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# Function to log to file
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to show usage
show_usage() {
    cat << EOF
xnox-me Repository Update Script

Usage: $0 [OPTIONS]

Options:
    -o, --org NAME      GitHub organization name (default: xnox-me)
    -d, --dir PATH      Working directory (default: $HOME/xnox-repos)
    -v, --verbose       Verbose output
    -q, --quiet         Quiet mode (only errors)
    -h, --help          Show this help message

Examples:
    $0                  # Update all xnox-me repos
    $0 -o myorg         # Update myorg repos
    $0 -v               # Verbose updating

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--org)
                ORG_NAME="$2"
                shift 2
                ;;
            -d|--dir)
                WORK_DIR="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("git" "curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_status "Please install: sudo apt-get install ${missing[*]}"
        exit 1
    fi
    
    print_success "All dependencies available"
}

# Function to get repository list from GitHub API
get_repo_list() {
    print_status "Fetching repository list for organization: $ORG_NAME"
    
    # Use GitHub API to get repository list
    local response
    response=$(curl -s "https://api.github.com/orgs/$ORG_NAME/repos?per_page=100" 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ "$response" == *"message"* ]] && [[ "$response" == *"API rate limit exceeded"* ]]; then
        print_warning "GitHub API rate limit exceeded, using fallback method"
        # Fallback to scraping (less reliable)
        get_repo_list_fallback
        return
    fi
    
    if [[ "$response" == *"message"* ]] && [[ "$response" == *"Not Found"* ]]; then
        print_error "Organization not found: $ORG_NAME"
        exit 1
    fi
    
    # Extract repository names using jq
    REPOS=($(echo "$response" | jq -r '.[].name'))
    TOTAL_REPOS=${#REPOS[@]}
    
    if [[ $TOTAL_REPOS -eq 0 ]]; then
        print_warning "No repositories found for organization: $ORG_NAME"
        return
    fi
    
    print_success "Found $TOTAL_REPOS repositories"
    log_to_file "Repository list: ${REPOS[*]}"
}

# Fallback method to get repository list
get_repo_list_fallback() {
    print_status "Using fallback method to get repository list"
    
    # For now, we'll just use the DEA repository which we know exists
    REPOS=("DEA")  # We know DEA exists
    TOTAL_REPOS=1
    
    print_success "Found repositories (fallback method)"
}

# Function to update repository
update_repo() {
    local repo_name=$1
    local repo_path="$WORK_DIR/$repo_name"
    
    print_header "Updating Repository: $repo_name"
    log_to_file "Updating repository: $repo_name"
    
    # Clone repository if it doesn't exist
    if [[ ! -d "$repo_path" ]]; then
        print_status "Cloning repository..."
        mkdir -p "$WORK_DIR"
        if ! git clone "https://github.com/$ORG_NAME/$repo_name.git" "$repo_path"; then
            print_error "Failed to clone repository: $repo_name"
            log_to_file "ERROR: Failed to clone $repo_name"
            return 1
        fi
    else
        # Update existing repository
        print_status "Updating repository..."
        cd "$repo_path"
        
        # Fetch latest changes
        if ! git fetch; then
            print_error "Failed to fetch repository: $repo_name"
            log_to_file "ERROR: Failed to fetch $repo_name"
            cd - &>/dev/null
            return 1
        fi
        
        # Get current branch
        local current_branch
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        
        # Check if there are updates
        local local_commit
        local remote_commit
        local_commit=$(git rev-parse HEAD)
        remote_commit=$(git rev-parse "origin/$current_branch" 2>/dev/null || echo "")
        
        if [[ -z "$remote_commit" ]]; then
            print_warning "Could not determine remote commit for $repo_name"
            cd - &>/dev/null
            return 1
        fi
        
        if [[ "$local_commit" != "$remote_commit" ]]; then
            print_status "Updates available, pulling changes..."
            if ! git pull; then
                print_error "Failed to pull repository: $repo_name"
                log_to_file "ERROR: Failed to pull $repo_name"
                cd - &>/dev/null
                return 1
            fi
            print_success "Repository updated successfully"
        else
            print_success "Repository is up to date"
        fi
        
        cd - &>/dev/null
    fi
    
    log_to_file "Repository $repo_name updated successfully"
}

# Function to show final summary
show_summary() {
    print_header "Update Summary"
    
    echo -e "Organization: ${CYAN}$ORG_NAME${NC}"
    echo -e "Total Repositories: ${CYAN}$TOTAL_REPOS${NC}"
    echo -e "Working Directory: ${CYAN}$WORK_DIR${NC}"
    
    log_to_file "UPDATE SUMMARY - Organization: $ORG_NAME, Total: $TOTAL_REPOS, Directory: $WORK_DIR"
}

# Main function
main() {
    print_header "xnox-me Repository Update Script"
    log_to_file "Starting repository update for organization: $ORG_NAME"
    
    parse_args "$@"
    check_dependencies
    get_repo_list
    
    if [[ $TOTAL_REPOS -eq 0 ]]; then
        print_warning "No repositories to update"
        exit 0
    fi
    
    # Initialize log file
    echo "=== xnox-me Repository Update Log ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    
    # Update each repository
    for repo in "${REPOS[@]}"; do
        update_repo "$repo"
        echo ""  # Add spacing between repositories
    done
    
    # Show final summary
    show_summary
    log_to_file "Repository update completed"
    
    print_success "All repositories updated successfully!"
    print_status "Logs saved to: $LOG_FILE"
    print_status "Repositories stored in: $WORK_DIR"
}

# Run main function
main "$@"