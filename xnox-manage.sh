#!/bin/bash

# xnox-me Repository Management Wrapper
# Single script to manage all xnox-me GitHub repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Function to show usage
show_usage() {
    cat << EOF
xnox-me Repository Management Wrapper

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    check       Run health check on all repositories
    update      Update all repositories
    both        Run both check and update
    help        Show this help message

Check Options:
    -v, --verbose       Verbose output for check
    -r, --report        Generate detailed report for check
    -q, --quiet         Quiet mode for check

Update Options:
    -v, --verbose       Verbose output for update

Global Options:
    -o, --org NAME      GitHub organization name (default: xnox-me)
    -d, --dir PATH      Working directory for repositories

Examples:
    $0 check                    # Run health check
    $0 update                   # Update all repositories
    $0 both -v                  # Run both with verbose output
    $0 check -r -o myorg        # Check with report for custom org

EOF
}

# Parse command line arguments
parse_args() {
    COMMAND=""
    CHECK_ARGS=()
    UPDATE_ARGS=()
    GLOBAL_ARGS=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            check|update|both|help)
                COMMAND="$1"
                shift
                ;;
            -v|--verbose|-r|--report|-q|--quiet|-o|--org|-d|--dir)
                # Store arguments for both commands
                if [[ "$1" == "-o" ]] || [[ "$1" == "--org" ]] || [[ "$1" == "-d" ]] || [[ "$1" == "--dir" ]]; then
                    GLOBAL_ARGS+=("$1" "$2")
                    CHECK_ARGS+=("$1" "$2")
                    UPDATE_ARGS+=("$1" "$2")
                    shift 2
                else
                    if [[ "$COMMAND" == "check" ]] || [[ "$COMMAND" == "both" ]]; then
                        CHECK_ARGS+=("$1")
                    fi
                    if [[ "$COMMAND" == "update" ]] || [[ "$COMMAND" == "both" ]]; then
                        UPDATE_ARGS+=("$1")
                    fi
                    shift
                fi
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to run health check
run_check() {
    print_header "Running Repository Health Check"
    
    # Build command
    local cmd="./xnox-repo-checker.sh"
    for arg in "${CHECK_ARGS[@]}"; do
        cmd+=" $arg"
    done
    
    print_status "Executing: $cmd"
    eval "$cmd"
}

# Function to run update
run_update() {
    print_header "Running Repository Update"
    
    # Build command
    local cmd="./xnox-update-all.sh"
    for arg in "${UPDATE_ARGS[@]}"; do
        cmd+=" $arg"
    done
    
    print_status "Executing: $cmd"
    eval "$cmd"
}

# Main function
main() {
    print_header "xnox-me Repository Management"
    
    parse_args "$@"
    
    case "$COMMAND" in
        check)
            run_check
            ;;
        update)
            run_update
            ;;
        both)
            run_check
            echo ""
            run_update
            ;;
        help|*)
            show_usage
            ;;
    esac
    
    print_success "Operation completed!"
}

# Run main function
main "$@"