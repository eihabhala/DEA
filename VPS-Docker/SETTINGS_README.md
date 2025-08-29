# 🎯 DEA Trading System - Complete Settings Configuration Guide

This document provides a comprehensive overview of all configuration settings for the DEA trading system, organized by component for easy reference.

## 📋 Table of Contents

- [Overview](#overview)
- [Environment Configuration (.env)](#environment-configuration-env)
- [MetaTrader Settings](#metatrader-settings)
- [Webhook Server Configuration](#webhook-server-configuration)
- [Database Settings](#database-settings)
- [Monitoring Services](#monitoring-services)
- [VNC Access Configuration](#vnc-access-configuration)
- [API Endpoints](#api-endpoints)
- [Security Configuration](#security-configuration)
- [Connection Files Mapping](#connection-files-mapping)

## 🎯 Overview

The DEA trading system uses multiple configuration files to manage different aspects of the trading environment:

| File | Purpose | Location |
|------|---------|----------|
| [.env](.env) | Environment variables and core settings | `/home/eboalking/DEA/VPS-Docker/.env` |
| [config/connections.conf](config/connections.conf) | Centralized connection settings | `/home/eboalking/DEA/VPS-Docker/config/connections.conf` |
| [config/webhook.yaml](config/webhook.yaml) | Webhook server configuration | `/home/eboalking/DEA/VPS-Docker/config/webhook.yaml` |
| [config/mt4/terminal.ini](config/mt4/terminal.ini) | MT4 terminal settings | `/home/eboalking/DEA/VPS-Docker/config/mt4/terminal.ini` |
| [config/mt5/terminal.ini](config/mt5/terminal.ini) | MT5 terminal settings | `/home/eboalking/DEA/VPS-Docker/config/mt5/terminal.ini` |

## 🔧 Environment Configuration (.env)

The [.env](file:///home/eboalking/DEA/VPS-Docker/.env) file contains the core environment variables for the entire system:

### Platform Configuration
```env
MT_PLATFORM=MT5                    # MT4 or MT5
DEPLOY_MODE=production             # production or development
```

### MetaTrader Settings
```env
# MetaTrader 4 Configuration
MT4_SERVER=ICMarketsSC-Demo02      # Broker server
MT4_LOGIN=21287281                 # Account number
MT4_PASSWORD=voan78                # Account password

# MetaTrader 5 Configuration  
MT5_SERVER=ICMarketsSC-Demo        # Broker server
MT5_LOGIN=52486172                 # Account number
MT5_PASSWORD=WfW&HqF2V8J7Lp        # Account password
```

### Webhook Configuration
```env
WEBHOOK_PORT=5000                  # Port for webhook server
WEBHOOK_TOKEN=dea_secure_webhook_token_2024 # Authentication token
```

### Database Configuration
```env
POSTGRES_DB=trading_db             # Database name
POSTGRES_USER=trader               # Database user
POSTGRES_PASSWORD=SecureTrading2024 # Database password
```

### Redis Configuration
```env
REDIS_PASSWORD=SecureRedis2024     # Redis password
```

### VNC Configuration
```env
VNC_PASSWORD=trading123            # VNC password
VNC_ENABLED=false                  # Enable VNC access
```

### Monitoring Configuration
```env
GRAFANA_PASSWORD=admin123          # Grafana admin password
MONITORING_ENABLED=true            # Enable monitoring stack
```

## 📈 MetaTrader Settings

### MetaTrader 4 Terminal Configuration ([config/mt4/terminal.ini](file:///home/eboalking/DEA/VPS-Docker/config/mt4/terminal.ini))

```ini
[Common]
Login=21287281
Password=voan78
Server=ICMarketsSC-Demo02
AutoLogin=true

[Expert]
AllowLive=true
AllowImport=true
AllowWebRequest=true
```

### MetaTrader 5 Terminal Configuration ([config/mt5/terminal.ini](file:///home/eboalking/DEA/VPS-Docker/config/mt5/terminal.ini))

```ini
[Common]
Login=52486172
Password=WfW&HqF2V8J7Lp
Server=ICMarketsSC-Demo
AutoLogin=true

[Expert]
AllowLive=true
AllowImport=true
AllowWebRequest=true
```

## 🌐 Webhook Server Configuration

### YAML Configuration ([config/webhook.yaml](file:///home/eboalking/DEA/VPS-Docker/config/webhook.yaml))

```yaml
server:
  host: "0.0.0.0"
  port: 5000
  debug: false
  
webhook:
  token: "dea_secure_webhook_token_2024"
  rate_limit: 1000  # requests per minute per IP
  allowed_ips: []   # empty list means all IPs allowed
  
metatrader:
  communication_port: 8081
  connection_timeout: 5
  retry_attempts: 3
  
trading:
  max_positions: 5
  risk_percent: 2.0
  max_lot_size: 1.0
  min_lot_size: 0.01
```

## 🗄️ Database Settings

### PostgreSQL
- **Host**: localhost
- **Port**: 5432
- **Database**: trading_db
- **Username**: trader
- **Password**: SecureTrading2024
- **Connection String**: `postgresql://trader:SecureTrading2024@localhost:5432/trading_db`

### Redis
- **Host**: localhost
- **Port**: 6379
- **Password**: SecureRedis2024
- **Database**: 0
- **Connection String**: `redis://:SecureRedis2024@localhost:6379/0`

## 📊 Monitoring Services

### Grafana
- **Host**: localhost
- **Port**: 3000
- **Username**: admin
- **Password**: admin123
- **URL**: http://localhost:3000

### Prometheus
- **Host**: localhost
- **Port**: 9090
- **URL**: http://localhost:9090

## 🖥️ VNC Access Configuration

### MetaTrader 4
- **Host**: localhost
- **Port**: 5901
- **Password**: trading123
- **Platform**: MetaTrader 4

### MetaTrader 5
- **Host**: localhost
- **Port**: 5902
- **Password**: trading123
- **Platform**: MetaTrader 5

## 🔌 API Endpoints

### Webhook Server Endpoints
- **Health Check**: `GET http://localhost:5000/health`
- **Status**: `GET http://localhost:5000/status`
- **Webhook**: `POST http://localhost:5000/webhook`

### External Access
- **Webhook URL**: `http://5.189.129.137:5000/webhook`

## 🔒 Security Configuration

### Webhook Security
- **Token Authentication**: Enabled with token `dea_secure_webhook_token_2024`
- **Rate Limiting**: 1000 requests per minute per IP
- **IP Filtering**: All IPs allowed (empty allowed_ips list)

### Database Security
- **PostgreSQL**: Password authentication
- **Redis**: Password authentication

### VNC Security
- **Password Protection**: Enabled with password `trading123`

## 🗂️ Connection Files Mapping

This section shows how the different configuration files relate to each other:

### Centralized Configuration ([config/connections.conf](file:///home/eboalking/DEA/VPS-Docker/config/connections.conf))

```ini
# MetaTrader 4 Settings
[MT4_ICMarkets_Demo]
Server=ICMarketsSC-Demo02
Login=21287281
Password=voan78

# MetaTrader 5 Settings
[MT5_ICMarkets_Demo]
Server=ICMarketsSC-Demo
Login=52486172
Password=WfW&HqF2V8J7Lp

# Webhook Server
[Webhook_Server]
Host=localhost
Port=5000
Token=dea_secure_webhook_token_2024

# Database Settings
[PostgreSQL]
Host=localhost
Port=5432
Database=trading_db
Username=trader
Password=SecureTrading2024

[Redis]
Host=localhost
Port=6379
Password=SecureRedis2024

# Monitoring
[Grafana]
Host=localhost
Port=3000
Username=admin
Password=admin123

[Prometheus]
Host=localhost
Port=9090

# VNC Access
[VNC_MT4]
Host=localhost
Port=5901
Password=trading123

[VNC_MT5]
Host=localhost
Port=5902
Password=trading123
```

## 🚀 Quick Start Commands

### Start All Services
```bash
cd /home/eboalking/DEA/VPS-Docker
./start-all-services.sh
```

### Test Webhook Server
```bash
# Health check
curl http://localhost:5000/health

# Status check
curl http://localhost:5000/status

# Send test signal
curl -X POST http://localhost:5000/webhook \
  -H "Content-Type: application/json" \
  -d '{"action": "BUY", "symbol": "EURUSD", "lot_size": 0.1}'
```

### Test Database Connections
```bash
# PostgreSQL
docker exec -it dea-postgres psql -U trader -d trading_db -c "SELECT version();"

# Redis
docker exec -it dea-redis redis-cli -a SecureRedis2024 ping
```

## 🛠️ Management Commands

### Service Management
```bash
# Start individual services
docker compose --profile mt5 up -d metatrader5
docker compose --profile monitoring up -d grafana prometheus
docker compose --profile database up -d postgres

# Stop all services
docker compose down

# View logs
docker compose logs webhook-server
```

## 📞 Support

For issues with configuration settings:
1. Check logs in `/home/eboalking/DEA/VPS-Docker/logs/`
2. Review configuration files in `/home/eboalking/DEA/VPS-Docker/config/`
3. Contact support with error messages and logs