#!/bin/bash

# AI Trading Expert Advisor - VPS Management Script
# Comprehensive management tools for containerized trading environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# Helper functions
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show usage
show_usage() {
    cat << EOF
AI Trading Expert Advisor - VPS Management Script

Usage: $0 COMMAND [OPTIONS]

Commands:
    start           Start all services
    stop            Stop all services
    restart         Restart all services
    status          Show status of all services
    logs            Show logs for specified service
    update          Update EA files and restart
    backup          Create backup of all data
    restore         Restore from backup
    monitor         Show real-time monitoring
    health          Perform health check
    optimize        Optimize system performance
    security        Run security audit
    cleanup         Clean up old logs and data

Service Management:
    start-mt4       Start only MT4 container
    start-mt5       Start only MT5 container
    start-webhook   Start only webhook server
    stop-mt4        Stop MT4 container
    stop-mt5        Stop MT5 container
    stop-webhook    Stop webhook server

Options:
    -f, --follow    Follow logs (for logs command)
    -n, --lines     Number of lines to show (default: 100)
    -s, --service   Specify service name
    -h, --help      Show this help

Examples:
    $0 start
    $0 logs --service mt5 --follow
    $0 backup --output /backup/trading-$(date +%Y%m%d)
    $0 monitor --interval 5

EOF
}

# Check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not available"
        exit 1
    fi
}

# Get service status
get_service_status() {
    local service=$1
    local status=$(docker-compose ps -q "$service" 2>/dev/null)
    
    if [[ -z "$status" ]]; then
        echo "not_created"
    else
        local running=$(docker inspect -f '{{.State.Running}}' "$status" 2>/dev/null)
        if [[ "$running" == "true" ]]; then
            echo "running"
        else
            echo "stopped"
        fi
    fi
}

# Start services
start_services() {
    local service=${1:-""}
    
    print_status "Starting services..."
    
    if [[ -n "$service" ]]; then
        docker-compose up -d "$service"
        print_success "$service started"
    else
        docker-compose up -d
        print_success "All services started"
    fi
}

# Stop services
stop_services() {
    local service=${1:-""}
    
    print_status "Stopping services..."
    
    if [[ -n "$service" ]]; then
        docker-compose stop "$service"
        print_success "$service stopped"
    else
        docker-compose stop
        print_success "All services stopped"
    fi
}

# Restart services
restart_services() {
    local service=${1:-""}
    
    print_status "Restarting services..."
    
    if [[ -n "$service" ]]; then
        docker-compose restart "$service"
        print_success "$service restarted"
    else
        docker-compose restart
        print_success "All services restarted"
    fi
}

# Show status
show_status() {
    print_status "=== Service Status ==="
    echo
    
    # Get list of services from docker-compose
    local services=$(docker-compose config --services 2>/dev/null)
    
    for service in $services; do
        local status=$(get_service_status "$service")
        local color=""
        
        case "$status" in
            "running") color="$GREEN" ;;
            "stopped") color="$YELLOW" ;;
            "not_created") color="$RED" ;;
        esac
        
        printf "%-20s ${color}%-12s${NC}\n" "$service:" "$status"
    done
    
    echo
    print_status "=== Resource Usage ==="
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "No running containers"
}

# Show logs
show_logs() {
    local service=${1:-""}
    local follow=${2:-false}
    local lines=${3:-100}
    
    if [[ -z "$service" ]]; then
        print_error "Service name required for logs command"
        exit 1
    fi
    
    local options="--tail=$lines"
    if [[ "$follow" == "true" ]]; then
        options="$options --follow"
    fi
    
    print_status "Showing logs for $service..."
    docker-compose logs $options "$service"
}

# Update EA files
update_ea() {
    local platform=${1:-"mt5"}
    
    print_status "Updating EA files for $platform..."
    
    # Copy EA files
    if [[ "$platform" == "mt4" ]]; then
        cp -r ../MQL4/* ./data/mt4/MQL4/ 2>/dev/null || true
        restart_services "metatrader4"
    else
        cp -r ../MQL5/* ./data/mt5/MQL5/ 2>/dev/null || true
        restart_services "metatrader5"
    fi
    
    print_success "EA files updated and service restarted"
}

# Create backup
create_backup() {
    local output_dir=${1:-"./backups/backup-$(date +%Y%m%d-%H%M%S)"}
    
    print_status "Creating backup..."
    
    mkdir -p "$output_dir"
    
    # Backup data directory
    print_status "Backing up data..."
    tar -czf "$output_dir/data.tar.gz" -C . data/
    
    # Backup configuration
    print_status "Backing up configuration..."
    tar -czf "$output_dir/config.tar.gz" -C . config/ .env docker-compose.yml
    
    # Backup database if running
    if [[ $(get_service_status "postgres") == "running" ]]; then
        print_status "Backing up database..."
        docker-compose exec -T postgres pg_dump -U trader trading_db > "$output_dir/database.sql"
    fi
    
    # Create backup info
    cat > "$output_dir/backup_info.txt" << EOF
Backup created: $(date)
Version: AI Trading EA VPS v1.0
Services: $(docker-compose config --services | tr '\n' ' ')
EOF

    print_success "Backup created: $output_dir"
}

# Restore from backup
restore_backup() {
    local backup_dir=${1:-""}
    
    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        print_error "Backup directory required and must exist"
        exit 1
    fi
    
    print_warning "This will overwrite current data. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    print_status "Restoring from backup: $backup_dir"
    
    # Stop services
    stop_services
    
    # Restore data
    if [[ -f "$backup_dir/data.tar.gz" ]]; then
        print_status "Restoring data..."
        tar -xzf "$backup_dir/data.tar.gz" -C .
    fi
    
    # Restore configuration
    if [[ -f "$backup_dir/config.tar.gz" ]]; then
        print_status "Restoring configuration..."
        tar -xzf "$backup_dir/config.tar.gz" -C .
    fi
    
    # Start services
    start_services
    
    # Restore database
    if [[ -f "$backup_dir/database.sql" ]]; then
        print_status "Restoring database..."
        sleep 10  # Wait for database to be ready
        docker-compose exec -T postgres psql -U trader -d trading_db < "$backup_dir/database.sql"
    fi
    
    print_success "Restore completed"
}

# Monitor system
monitor_system() {
    local interval=${1:-5}
    
    print_status "Starting system monitoring (Ctrl+C to exit)..."
    
    while true; do
        clear
        echo "=== AI Trading EA Monitoring - $(date) ==="
        echo
        
        # Service status
        show_status
        
        echo
        print_status "=== Recent Activity ==="
        
        # Recent signals
        if [[ $(get_service_status "webhook-server") == "running" ]]; then
            echo "Recent webhook calls:"
            docker-compose exec webhook-server tail -n 5 /app/logs/webhook.log 2>/dev/null | head -5 || echo "No recent activity"
        fi
        
        echo
        print_status "Next update in ${interval}s... (Ctrl+C to exit)"
        sleep "$interval"
    done
}

# Health check
health_check() {
    print_status "=== Health Check ==="
    echo
    
    local overall_health="healthy"
    
    # Check webhook server
    if curl -sf http://localhost:5000/health > /dev/null 2>&1; then
        print_success "Webhook server: healthy"
    else
        print_error "Webhook server: unhealthy"
        overall_health="unhealthy"
    fi
    
    # Check database
    if [[ $(get_service_status "postgres") == "running" ]]; then
        if docker-compose exec -T postgres pg_isready -U trader > /dev/null 2>&1; then
            print_success "Database: healthy"
        else
            print_error "Database: unhealthy"
            overall_health="unhealthy"
        fi
    else
        print_warning "Database: not running"
    fi
    
    # Check MetaTrader containers
    for platform in mt4 mt5; do
        local service="metatrader$platform"
        local container_name="dea-$platform"
        
        if [[ $(get_service_status "$service") == "running" ]]; then
            # Check if MT process is running
            if docker exec "$container_name" pgrep -f "terminal" > /dev/null 2>&1; then
                print_success "$platform: healthy"
            else
                print_warning "$platform: process not found"
            fi
        else
            print_status "$platform: not running"
        fi
    done
    
    echo
    if [[ "$overall_health" == "healthy" ]]; then
        print_success "Overall system health: HEALTHY"
    else
        print_error "Overall system health: UNHEALTHY"
    fi
}

# Optimize performance
optimize_system() {
    print_status "=== System Optimization ==="
    
    # Clean up Docker
    print_status "Cleaning up Docker resources..."
    docker system prune -f > /dev/null 2>&1
    
    # Optimize logs
    print_status "Rotating logs..."
    find ./logs -name "*.log" -size +100M -exec truncate -s 50M {} \;
    
    # Clear old signals
    print_status "Cleaning old signal files..."
    find ./data -name "*_signals.json" -mtime +7 -delete 2>/dev/null || true
    
    # Update container images
    print_status "Pulling latest images..."
    docker-compose pull
    
    print_success "System optimization completed"
}

# Security audit
security_audit() {
    print_status "=== Security Audit ==="
    
    local issues=0
    
    # Check file permissions
    print_status "Checking file permissions..."
    
    if [[ -r ".env" ]]; then
        local env_perms=$(stat -c "%a" .env)
        if [[ "$env_perms" != "600" ]]; then
            print_warning ".env file permissions too open ($env_perms). Fixing..."
            chmod 600 .env
        else
            print_success ".env file permissions: secure"
        fi
    fi
    
    # Check for default passwords
    print_status "Checking for default passwords..."
    
    if grep -q "change_me\|password\|admin123" .env 2>/dev/null; then
        print_error "Default passwords found in .env file"
        issues=$((issues + 1))
    else
        print_success "No default passwords found"
    fi
    
    # Check SSL configuration
    if [[ -n "$(grep SSL_DOMAIN .env | cut -d'=' -f2)" ]]; then
        if [[ -f "nginx/ssl/fullchain.pem" ]]; then
            print_success "SSL certificate found"
        else
            print_warning "SSL domain configured but certificate missing"
        fi
    fi
    
    echo
    if [[ $issues -eq 0 ]]; then
        print_success "Security audit passed"
    else
        print_error "Security audit found $issues issue(s)"
    fi
}

# Cleanup old data
cleanup_system() {
    print_status "=== System Cleanup ==="
    
    # Clean logs older than 30 days
    find ./logs -name "*.log" -mtime +30 -delete 2>/dev/null && \
        print_success "Old log files cleaned" || \
        print_status "No old log files to clean"
    
    # Clean backup files older than 7 days
    find ./backups -name "backup-*" -mtime +7 -exec rm -rf {} \; 2>/dev/null && \
        print_success "Old backup files cleaned" || \
        print_status "No old backup files to clean"
    
    # Clean Docker resources
    docker system prune -f > /dev/null 2>&1 && \
        print_success "Docker resources cleaned"
    
    print_success "System cleanup completed"
}

# Main function
main() {
    cd "$SCRIPT_DIR"
    check_docker_compose
    
    local command=${1:-""}
    local service=""
    local follow=false
    local lines=100
    local output=""
    
    # Parse arguments
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                service="$2"
                shift 2
                ;;
            -f|--follow)
                follow=true
                shift
                ;;
            -n|--lines)
                lines="$2"
                shift 2
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$service" ]]; then
                    service="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Execute commands
    case "$command" in
        start) start_services "$service" ;;
        stop) stop_services "$service" ;;
        restart) restart_services "$service" ;;
        status) show_status ;;
        logs) show_logs "$service" "$follow" "$lines" ;;
        update) update_ea "$service" ;;
        backup) create_backup "$output" ;;
        restore) restore_backup "$service" ;;
        monitor) monitor_system "$service" ;;
        health) health_check ;;
        optimize) optimize_system ;;
        security) security_audit ;;
        cleanup) cleanup_system ;;
        start-mt4) start_services "metatrader4" ;;
        start-mt5) start_services "metatrader5" ;;
        start-webhook) start_services "webhook-server" ;;
        stop-mt4) stop_services "metatrader4" ;;
        stop-mt5) stop_services "metatrader5" ;;
        stop-webhook) stop_services "webhook-server" ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"