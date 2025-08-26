#!/bin/bash

# AI Trading Expert Advisor - VPS Deployment Script
# Automated deployment for Docker containerized MT4/MT5 trading environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
MT_PLATFORM="MT5"
DOMAIN=""
SSL_EMAIL=""
BACKUP_ENABLED="true"
MONITORING_ENABLED="true"
VNC_ENABLED="false"
DEPLOY_MODE="production"

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

# Function to show usage
show_usage() {
    cat << EOF
AI Trading Expert Advisor - VPS Deployment Script

Usage: $0 [OPTIONS]

Options:
    -p, --platform      MetaTrader platform (MT4 or MT5) [default: MT5]
    -d, --domain        Domain name for SSL certificates
    -e, --email         Email for SSL certificate registration
    -m, --mode          Deployment mode (production, development) [default: production]
    --enable-vnc        Enable VNC access to MetaTrader GUI
    --disable-backup    Disable automatic backup service
    --disable-monitoring Disable monitoring stack (Grafana/Prometheus)
    -h, --help          Show this help message

Examples:
    $0 --platform MT5 --domain trading.example.com --email admin@example.com
    $0 --platform MT4 --enable-vnc --mode development
    $0 --platform MT5 --disable-monitoring

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--platform)
                MT_PLATFORM="$2"
                shift 2
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -e|--email)
                SSL_EMAIL="$2"
                shift 2
                ;;
            -m|--mode)
                DEPLOY_MODE="$2"
                shift 2
                ;;
            --enable-vnc)
                VNC_ENABLED="true"
                shift
                ;;
            --disable-backup)
                BACKUP_ENABLED="false"
                shift
                ;;
            --disable-monitoring)
                MONITORING_ENABLED="false"
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

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check system resources
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $MEMORY_GB -lt 4 ]]; then
        print_warning "System has less than 4GB RAM. Consider upgrading for better performance."
    fi
    
    # Check available disk space
    DISK_GB=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [[ $DISK_GB -lt 10 ]]; then
        print_error "Insufficient disk space. At least 10GB free space required."
        exit 1
    fi
    
    print_success "System requirements check passed"
}

# Setup directory structure
setup_directories() {
    print_status "Setting up directory structure..."
    
    # Create necessary directories
    mkdir -p {data/{mt4,mt5,webhook,backups},logs/{mt4,mt5,webhook,nginx},config/{mt4,mt5,webhook},nginx/ssl,monitoring/{grafana,prometheus}}
    
    # Set proper permissions
    chmod 755 data logs config
    chmod 700 config/webhook nginx/ssl
    
    print_success "Directory structure created"
}

# Generate configuration files
generate_configs() {
    print_status "Generating configuration files..."
    
    # Generate .env file
    cat > .env << EOF
# AI Trading Expert Advisor Configuration
# Generated on $(date)

# Platform Configuration
MT_PLATFORM=${MT_PLATFORM}
DEPLOY_MODE=${DEPLOY_MODE}

# MetaTrader Settings
MT4_SERVER=Demo-Server
MT4_LOGIN=12345678
MT4_PASSWORD=change_me
MT5_SERVER=Demo-Server  
MT5_LOGIN=12345678
MT5_PASSWORD=change_me

# Webhook Configuration
WEBHOOK_PORT=5000
WEBHOOK_TOKEN=$(openssl rand -hex 32)

# Database Configuration
POSTGRES_DB=trading_db
POSTGRES_USER=trader
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Redis Configuration
REDIS_PASSWORD=$(openssl rand -base64 32)

# VNC Configuration
VNC_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-8)
VNC_ENABLED=${VNC_ENABLED}

# SSL Configuration
SSL_DOMAIN=${DOMAIN}
SSL_EMAIL=${SSL_EMAIL}

# Monitoring
GRAFANA_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
MONITORING_ENABLED=${MONITORING_ENABLED}

# Backup Configuration
BACKUP_ENABLED=${BACKUP_ENABLED}
BACKUP_RETENTION=7

# Resource Limits
MT_MEMORY_LIMIT=2g
MT_CPU_LIMIT=1.0
WEBHOOK_MEMORY_LIMIT=512m
WEBHOOK_CPU_LIMIT=0.5
EOF

    # Generate webhook configuration
    cat > config/webhook/config.yaml << EOF
server:
  host: 0.0.0.0
  port: 5000
  debug: $([ "$DEPLOY_MODE" = "development" ] && echo "true" || echo "false")

metatrader:
  mt4_port: 8081
  mt5_port: 8082
  timeout: 30

database:
  host: postgres
  port: 5432
  name: trading_db
  user: trader
  # password loaded from environment

redis:
  host: redis
  port: 6379
  db: 0

security:
  # auth_token loaded from environment
  rate_limit: 1000
  allowed_ips: []

logging:
  level: INFO
  file: /app/logs/webhook.log
EOF

    # Generate Nginx configuration
    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream webhook_backend {
        server webhook-server:5000;
    }

    server {
        listen 80;
        server_name ${DOMAIN:-localhost};
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            $([ -n "$DOMAIN" ] && echo "return 301 https://\$server_name\$request_uri;" || echo "proxy_pass http://webhook_backend;")
        }
    }
    
    $([ -n "$DOMAIN" ] && cat << 'SSLCONF'
    server {
        listen 443 ssl http2;
        server_name ${DOMAIN};
        
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        
        location / {
            proxy_pass http://webhook_backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
SSLCONF
)
}
EOF

    print_success "Configuration files generated"
}

# Setup SSL certificates
setup_ssl() {
    if [[ -n "$DOMAIN" && -n "$SSL_EMAIL" ]]; then
        print_status "Setting up SSL certificates for $DOMAIN..."
        
        # Create certbot container for initial certificate
        docker run --rm \
            -v "$(pwd)/nginx/ssl:/etc/letsencrypt/live/$DOMAIN:rw" \
            -v "$(pwd)/nginx/www:/var/www/certbot:rw" \
            certbot/certbot certonly \
            --webroot \
            --webroot-path=/var/www/certbot \
            --email "$SSL_EMAIL" \
            --agree-tos \
            --no-eff-email \
            -d "$DOMAIN"
        
        if [[ $? -eq 0 ]]; then
            print_success "SSL certificate obtained for $DOMAIN"
        else
            print_warning "Failed to obtain SSL certificate. Continuing without SSL..."
        fi
    else
        print_status "Skipping SSL setup (no domain/email provided)"
    fi
}

# Build and start containers
deploy_containers() {
    print_status "Building and starting containers..."
    
    # Determine which profiles to activate
    PROFILES=""
    
    # Always include the selected MT platform
    if [[ "$MT_PLATFORM" == "MT4" ]]; then
        PROFILES="mt4"
    else
        PROFILES="mt5"
    fi
    
    # Add monitoring if enabled
    if [[ "$MONITORING_ENABLED" == "true" ]]; then
        PROFILES="$PROFILES,monitoring"
    fi
    
    # Add backup if enabled
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        PROFILES="$PROFILES,backup"
    fi
    
    # Add database
    PROFILES="$PROFILES,database"
    
    # Build and start
    export COMPOSE_PROFILES="$PROFILES"
    docker-compose up -d --build
    
    print_success "Containers started with profiles: $PROFILES"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for webhook server
    for i in {1..30}; do
        if curl -sf http://localhost:5000/health > /dev/null 2>&1; then
            print_success "Webhook server is ready"
            break
        fi
        if [[ $i -eq 30 ]]; then
            print_error "Webhook server failed to start"
            exit 1
        fi
        sleep 2
    done
    
    # Wait for database
    for i in {1..30}; do
        if docker-compose exec -T postgres pg_isready > /dev/null 2>&1; then
            print_success "Database is ready"
            break
        fi
        if [[ $i -eq 30 ]]; then
            print_error "Database failed to start"
            exit 1
        fi
        sleep 2
    done
    
    print_success "All services are ready"
}

# Setup monitoring dashboards
setup_monitoring() {
    if [[ "$MONITORING_ENABLED" == "true" ]]; then
        print_status "Setting up monitoring dashboards..."
        
        # Wait for Grafana to be ready
        sleep 10
        
        # Import dashboards (this would be expanded with actual dashboard imports)
        print_success "Monitoring setup complete"
        print_status "Grafana dashboard: http://localhost:3000 (admin/$(grep GRAFANA_PASSWORD .env | cut -d'=' -f2))"
    fi
}

# Display deployment summary
show_summary() {
    print_success "=== Deployment Complete ==="
    echo
    print_status "Platform: $MT_PLATFORM"
    print_status "Mode: $DEPLOY_MODE"
    
    if [[ -n "$DOMAIN" ]]; then
        print_status "Domain: https://$DOMAIN"
    else
        print_status "Local access: http://localhost"
    fi
    
    echo
    print_status "=== Access Information ==="
    print_status "Webhook endpoint: $([ -n "$DOMAIN" ] && echo "https://$DOMAIN/webhook" || echo "http://localhost:5000/webhook")"
    print_status "Health check: $([ -n "$DOMAIN" ] && echo "https://$DOMAIN/health" || echo "http://localhost:5000/health")"
    
    if [[ "$VNC_ENABLED" == "true" ]]; then
        VNC_PORT=$([ "$MT_PLATFORM" == "MT4" ] && echo "5901" || echo "5902")
        print_status "VNC access: localhost:$VNC_PORT (password: $(grep VNC_PASSWORD .env | cut -d'=' -f2))"
    fi
    
    if [[ "$MONITORING_ENABLED" == "true" ]]; then
        print_status "Grafana: http://localhost:3000 (admin/$(grep GRAFANA_PASSWORD .env | cut -d'=' -f2))"
        print_status "Prometheus: http://localhost:9090"
    fi
    
    echo
    print_status "=== Important Files ==="
    print_status "Environment: .env"
    print_status "Logs: logs/"
    print_status "Data: data/"
    print_status "Configuration: config/"
    
    echo
    print_status "=== Next Steps ==="
    print_status "1. Update MetaTrader credentials in .env file"
    print_status "2. Copy your EA files to data/${MT_PLATFORM,,}/"
    print_status "3. Configure your broker settings"
    print_status "4. Test webhook with: curl -X POST $([ -n "$DOMAIN" ] && echo "https://$DOMAIN/webhook" || echo "http://localhost:5000/webhook") -H 'Content-Type: application/json' -d '{\"action\":\"BUY\",\"symbol\":\"EURUSD\"}'"
    
    echo
    print_success "Deployment completed successfully!"
}

# Main deployment function
main() {
    echo "=== AI Trading Expert Advisor - VPS Deployment ==="
    echo
    
    parse_args "$@"
    check_requirements
    setup_directories
    generate_configs
    
    if [[ -n "$DOMAIN" ]]; then
        setup_ssl
    fi
    
    deploy_containers
    wait_for_services
    setup_monitoring
    show_summary
}

# Run main function
main "$@"