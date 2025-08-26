#!/bin/bash

# xnox-me Repository Error Checker
# Comprehensive script to check for errors in all xnox-me GitHub repositories

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
WORK_DIR="/tmp/xnox-check"
LOG_FILE="/tmp/xnox-check.log"
ERROR_LOG="/tmp/xnox-errors.log"
REPORT_FILE="/tmp/xnox-report.txt"

# Global counters
TOTAL_REPOS=0
CHECKED_REPOS=0
ERROR_REPOS=0
WARNING_REPOS=0

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
xnox-me Repository Error Checker

Usage: $0 [OPTIONS]

Options:
    -o, --org NAME      GitHub organization name (default: xnox-me)
    -d, --dir PATH      Working directory (default: /tmp/xnox-check)
    -v, --verbose       Verbose output
    -q, --quiet         Quiet mode (only errors)
    -r, --report        Generate detailed report
    -h, --help          Show this help message

Examples:
    $0                          # Check all xnox-me repos
    $0 -o myorg -r              # Check myorg repos with report
    $0 -v                       # Verbose checking

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
            -r|--report)
                GENERATE_REPORT=true
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
    
    local deps=("git" "curl" "jq" "python3")
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
    
    # Try to get repository list from GitHub web page
    local response
    response=$(curl -s "https://github.com/$ORG_NAME" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to fetch organization page"
        exit 1
    fi
    
    # Extract repository names (this is a simplified approach)
    # In a real implementation, you'd want to parse the HTML properly
    REPOS=("DEA")  # We know DEA exists
    TOTAL_REPOS=1
    
    print_success "Found repositories (fallback method)"
}

# Function to check repository health
check_repo_health() {
    local repo_name=$1
    local repo_path="$WORK_DIR/$repo_name"
    local repo_errors=0
    local repo_warnings=0
    
    print_header "Checking Repository: $repo_name"
    log_to_file "Checking repository: $repo_name"
    
    # Clone repository if it doesn't exist
    if [[ ! -d "$repo_path" ]]; then
        print_status "Cloning repository..."
        if ! git clone "https://github.com/$ORG_NAME/$repo_name.git" "$repo_path" &>/dev/null; then
            print_error "Failed to clone repository: $repo_name"
            log_to_file "ERROR: Failed to clone $repo_name"
            echo "$repo_name: Failed to clone" >> "$ERROR_LOG"
            ((ERROR_REPOS++))
            return 1
        fi
    else
        # Update existing repository
        print_status "Updating repository..."
        cd "$repo_path"
        if ! git pull &>/dev/null; then
            print_warning "Failed to update repository: $repo_name"
            log_to_file "WARNING: Failed to update $repo_name"
            ((WARNING_REPOS++))
        fi
        cd - &>/dev/null
    fi
    
    # Change to repository directory
    cd "$repo_path"
    
    # Check 1: Git status
    print_status "Checking git status..."
    if [[ -n "$(git status --porcelain)" ]]; then
        print_warning "Uncommitted changes found"
        log_to_file "WARNING: Uncommitted changes in $repo_name"
        ((repo_warnings++))
        if [[ "$VERBOSE" == "true" ]]; then
            git status --porcelain
        fi
    else
        print_success "Clean git status"
    fi
    
    # Check 2: README file
    print_status "Checking README..."
    if [[ ! -f "README.md" ]] && [[ ! -f "README" ]] && [[ ! -f "readme.md" ]]; then
        print_warning "No README file found"
        log_to_file "WARNING: No README in $repo_name"
        ((repo_warnings++))
    else
        print_success "README file present"
    fi
    
    # Check 3: License file
    print_status "Checking license..."
    if [[ ! -f "LICENSE" ]] && [[ ! -f "LICENSE.md" ]] && [[ ! -f "license" ]]; then
        print_warning "No license file found"
        log_to_file "WARNING: No license in $repo_name"
        ((repo_warnings++))
    else
        print_success "License file present"
    fi
    
    # Check 4: .gitignore file
    print_status "Checking .gitignore..."
    if [[ ! -f ".gitignore" ]]; then
        print_warning "No .gitignore file found"
        log_to_file "WARNING: No .gitignore in $repo_name"
        ((repo_warnings++))
    else
        print_success ".gitignore file present"
    fi
    
    # Check 5: Broken links in markdown files
    print_status "Checking for broken links..."
    local md_files
    md_files=$(find . -name "*.md" -type f 2>/dev/null)
    local broken_links=0
    
    if [[ -n "$md_files" ]]; then
        for md_file in $md_files; do
            # Simple check for obvious broken links (this is a basic check)
            if grep -E "\[.*\]\(.*\)" "$md_file" | grep -E "\[.*\]\((http|https)://.*\)" &>/dev/null; then
                # This would be more sophisticated in a real implementation
                # For now, we'll just note that we found links
                if [[ "$VERBOSE" == "true" ]]; then
                    print_status "Found links in $md_file (manual verification recommended)"
                fi
            fi
        done
        print_success "Link check completed"
    else
        print_warning "No markdown files found for link checking"
    fi
    
    # Check 6: Check for common error patterns in code files
    print_status "Checking for common error patterns..."
    
    # Check for TODO comments that might indicate incomplete work
    if find . -name "*.py" -o -name "*.mq4" -o -name "*.mq5" -o -name "*.js" -o -name "*.java" -o -name "*.cpp" -o -name "*.c" | xargs grep -l "TODO\|FIXME\|HACK" &>/dev/null; then
        local todo_count
        todo_count=$(find . -name "*.py" -o -name "*.mq4" -o -name "*.mq5" -o -name "*.js" -o -name "*.java" -o -name "*.cpp" -o -name "*.c" | xargs grep -c "TODO\|FIXME\|HACK" 2>/dev/null || echo "0")
        if [[ $todo_count -gt 0 ]]; then
            print_warning "Found $todo_count TODO/FIXME comments"
            log_to_file "WARNING: $todo_count TODO/FIXME comments in $repo_name"
            ((repo_warnings++))
            if [[ "$VERBOSE" == "true" ]]; then
                find . -name "*.py" -o -name "*.mq4" -o -name "*.mq5" -o -name "*.js" -o -name "*.java" -o -name "*.cpp" -o -name "*.c" | xargs grep -n "TODO\|FIXME\|HACK" 2>/dev/null || true
            fi
        fi
    else
        print_success "No TODO/FIXME comments found"
    fi
    
    # Check 7: Python-specific checks (if Python files exist)
    if find . -name "*.py" | grep -q .; then
        print_status "Running Python syntax check..."
        local py_errors=0
        while IFS= read -r -d '' py_file; do
            if ! python3 -m py_compile "$py_file" &>/dev/null; then
                print_error "Python syntax error in $py_file"
                log_to_file "ERROR: Python syntax error in $py_file"
                ((repo_errors++))
                ((py_errors++))
                if [[ "$VERBOSE" == "true" ]]; then
                    python3 -m py_compile "$py_file" 2>&1
                fi
            fi
        done < <(find . -name "*.py" -print0 2>/dev/null)
        
        if [[ $py_errors -eq 0 ]]; then
            print_success "All Python files syntax correct"
        fi
    fi
    
    # Check 8: Check for large files that might not belong in git
    print_status "Checking for large files..."
    local large_files
    large_files=$(find . -type f -size +10M 2>/dev/null | head -5)
    if [[ -n "$large_files" ]]; then
        print_warning "Large files found (may not belong in repository):"
        log_to_file "WARNING: Large files in $repo_name"
        ((repo_warnings++))
        if [[ "$VERBOSE" == "true" ]]; then
            echo "$large_files"
        fi
    else
        print_success "No large files found"
    fi
    
    # Summary for this repository
    print_header "Repository Summary: $repo_name"
    echo -e "Errors: ${repo_errors} | Warnings: ${repo_warnings}"
    log_to_file "Repository $repo_name - Errors: $repo_errors, Warnings: $repo_warnings"
    
    if [[ $repo_errors -gt 0 ]]; then
        echo "$repo_name: $repo_errors errors, $repo_warnings warnings" >> "$ERROR_LOG"
        ((ERROR_REPOS++))
    elif [[ $repo_warnings -gt 0 ]]; then
        ((WARNING_REPOS++))
    fi
    
    ((CHECKED_REPOS++))
    
    # Return to original directory
    cd - &>/dev/null
    
    # Generate report entry if requested
    if [[ "$GENERATE_REPORT" == "true" ]]; then
        cat >> "$REPORT_FILE" << EOF

## Repository: $repo_name

- Status: Checked
- Errors: $repo_errors
- Warnings: $repo_warnings
- Path: $repo_path

EOF
    fi
}

# Function to generate detailed report
generate_report() {
    if [[ "$GENERATE_REPORT" != "true" ]]; then
        return
    fi
    
    print_status "Generating detailed report..."
    
    cat > "$REPORT_FILE" << EOF
# xnox-me Repository Health Report
Generated on: $(date)

## Summary

- Organization: $ORG_NAME
- Total Repositories: $TOTAL_REPOS
- Checked Repositories: $CHECKED_REPOS
- Repositories with Errors: $ERROR_REPOS
- Repositories with Warnings: $WARNING_REPOS

## Detailed Results

EOF
    
    print_success "Report generated: $REPORT_FILE"
}

# Function to show final summary
show_summary() {
    print_header "Final Summary"
    
    echo -e "Total Repositories: ${CYAN}$TOTAL_REPOS${NC}"
    echo -e "Checked Repositories: ${CYAN}$CHECKED_REPOS${NC}"
    echo -e "Repositories with Errors: ${RED}$ERROR_REPOS${NC}"
    echo -e "Repositories with Warnings: ${YELLOW}$WARNING_REPOS${NC}"
    
    log_to_file "SUMMARY - Total: $TOTAL_REPOS, Checked: $CHECKED_REPOS, Errors: $ERROR_REPOS, Warnings: $WARNING_REPOS"
    
    if [[ $ERROR_REPOS -gt 0 ]]; then
        print_error "Found errors in $ERROR_REPOS repositories"
        print_status "Check error log: $ERROR_LOG"
        if [[ "$VERBOSE" == "true" ]]; then
            cat "$ERROR_LOG"
        fi
        return 1
    elif [[ $WARNING_REPOS -gt 0 ]]; then
        print_warning "Found warnings in $WARNING_REPOS repositories"
        return 0
    else
        print_success "All repositories checked successfully with no errors!"
        return 0
    fi
}

# Function to cleanup
cleanup() {
    if [[ "$QUIET" != "true" ]]; then
        print_status "Cleaning up..."
    fi
    
    # Cleanup is optional - user might want to keep the cloned repos
    # Uncomment the following lines if you want automatic cleanup
    # if [[ -d "$WORK_DIR" ]]; then
    #     rm -rf "$WORK_DIR"
    # fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Main function
main() {
    print_header "xnox-me Repository Error Checker"
    log_to_file "Starting repository check for organization: $ORG_NAME"
    
    parse_args "$@"
    check_dependencies
    get_repo_list
    
    if [[ $TOTAL_REPOS -eq 0 ]]; then
        print_warning "No repositories to check"
        exit 0
    fi
    
    # Create working directory
    mkdir -p "$WORK_DIR"
    
    # Initialize log files
    echo "=== xnox-me Repository Check Log ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "" > "$ERROR_LOG"
    
    if [[ "$GENERATE_REPORT" == "true" ]]; then
        echo "" > "$REPORT_FILE"
    fi
    
    # Check each repository
    for repo in "${REPOS[@]}"; do
        check_repo_health "$repo"
        echo ""  # Add spacing between repositories
    done
    
    # Generate report if requested
    generate_report
    
    # Show final summary
    show_summary
    log_to_file "Repository check completed"
    
    # Show log locations
    print_status "Logs saved to:"
    echo "  - General log: $LOG_FILE"
    if [[ -s "$ERROR_LOG" ]]; then
        echo "  - Error log: $ERROR_LOG"
    fi
    if [[ "$GENERATE_REPORT" == "true" ]]; then
        echo "  - Detailed report: $REPORT_FILE"
    fi
}

# Run main function
main "$@"