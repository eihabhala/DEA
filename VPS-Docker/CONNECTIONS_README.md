# DEA Trading System - Connection Settings Guide

This document provides comprehensive information about all connection settings for the DEA trading system.

## 📋 Overview of Connection Settings

All connection settings are configured in the following files:
- `/home/eboalking/DEA/VPS-Docker/config/connections.conf` - Centralized connection settings
- `/home/eboalking/DEA/VPS-Docker/config/mt4/terminal.ini` - MT4 terminal configuration
- `/home/eboalking/DEA/VPS-Docker/config/mt5/terminal.ini` - MT5 terminal configuration
- `/home/eboalking/DEA/VPS-Docker/config/webhook.yaml` - Webhook server configuration
- `/home/eboalking/DEA/VPS-Docker/.env` - Environment variables

## 🔧 MetaTrader Connection Settings

### MetaTrader 4 (ICMarkets Demo)
- **Server**: ICMarketsSC-Demo02
- **Login**: 21287281
- **Password**: voan78
- **Platform**: MetaTrader 4
- **Account Type**: Demo

### MetaTrader 5 (ICMarkets Demo)
- **Server**: ICMarketsSC-Demo
- **Login**: 52486172
- **Password**: WfW&HqF2V8J7Lp
- **Platform**: MetaTrader 5
- **Account Type**: Demo

## 🌐 Webhook Server Settings

- **Host**: localhost
- **Port**: 5000
- **Token**: dea_secure_webhook_token_2024
- **Protocol**: HTTP

### API Endpoints:
- **Health Check**: `http://localhost:5000/health`
- **Status**: `http://localhost:5000/status`
- **Webhook**: `http://localhost:5000/webhook` (POST only)

## 🗄️ Database Connection Settings

### PostgreSQL
- **Host**: localhost
- **Port**: 5432
- **Database**: trading_db
- **Username**: trader
- **Password**: SecureTrading2024

### Redis
- **Host**: localhost
- **Port**: 6379
- **Password**: SecureRedis2024
- **Database**: 0

## 📊 Monitoring Connection Settings

### Grafana
- **Host**: localhost
- **Port**: 3000
- **Username**: admin
- **Password**: admin123

### Prometheus
- **Host**: localhost
- **Port**: 9090

## 🖥️ VNC Access Settings

### MetaTrader 4
- **Host**: localhost
- **Port**: 5901
- **Password**: trading123

### MetaTrader 5
- **Host**: localhost
- **Port**: 5902
- **Password**: trading123

## ▶️ Starting All Services

To start all services with the proper connection settings, run:

```bash
cd /home/eboalking/DEA/VPS-Docker
./start-all-services.sh
```

## 🧪 Testing Connection Settings

### Test Webhook Server
```bash
# Check health
curl http://localhost:5000/health

# Check status
curl http://localhost:5000/status

# Send test signal
curl -X POST http://localhost:5000/webhook \
  -H "Content-Type: application/json" \
  -d '{"action": "BUY", "symbol": "EURUSD", "lot_size": 0.1}'
```

### Test Database Connections
```bash
# Test PostgreSQL connection
docker exec -it dea-postgres psql -U trader -d trading_db -c "SELECT version();"

# Test Redis connection
docker exec -it dea-redis redis-cli -a SecureRedis2024 ping
```

## 🔒 Security Notes

1. All passwords and tokens are configured in the `.env` file
2. Webhook authentication is enabled with token-based security
3. Rate limiting is configured (1000 requests per minute per IP)
4. VNC access is password protected
5. Database connections use secure authentication

## 🔄 Service Management

### Start Individual Services
```bash
# Start only MT5
docker compose --profile mt5 up -d metatrader5

# Start only monitoring
docker compose --profile monitoring up -d grafana prometheus

# Start only database
docker compose --profile database up -d postgres
```

### Stop All Services
```bash
cd /home/eboalking/DEA/VPS-Docker
docker compose down
```

### View Service Logs
```bash
# View webhook server logs
docker compose logs webhook-server

# View MT5 logs
docker compose logs metatrader5

# View all logs
docker compose logs
```

## 🛠️ Troubleshooting

### Common Issues and Solutions

1. **Webhook Server Not Responding**
   - Check if the service is running: `docker compose ps`
   - Restart the service: `docker compose restart webhook-server`

2. **MetaTrader Container Not Starting**
   - Check logs: `docker compose logs metatrader5`
   - Ensure VNC client is not already connected to the port

3. **Database Connection Issues**
   - Verify PostgreSQL is running: `docker compose ps postgres`
   - Check credentials in `.env` file

4. **Monitoring Services Not Accessible**
   - Check if ports 3000 (Grafana) and 9090 (Prometheus) are open
   - Restart monitoring services: `docker compose restart grafana prometheus`

## 📞 Support

For additional help with connection settings:
1. Check the logs in `/home/eboalking/DEA/VPS-Docker/logs/`
2. Review configuration files in `/home/eboalking/DEA/VPS-Docker/config/`
3. Contact support with the error messages and logs