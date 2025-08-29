# 🚀 DEA Trading System - Quick Reference Guide

This is a quick reference for the most important settings and commands you'll need to work with the DEA trading system.

## 🔧 Essential Settings

### MetaTrader Accounts

**MT4 Demo Account:**
- Server: `ICMarketsSC-Demo02`
- Login: `21287281`
- Password: `voan78`

**MT5 Demo Account:**
- Server: `ICMarketsSC-Demo`
- Login: `52486172`
- Password: `WfW&HqF2V8J7Lp`

### Webhook Server
- **Port**: 5000
- **Token**: `dea_secure_webhook_token_2024`
- **Health Check**: `http://localhost:5000/health`
- **Webhook Endpoint**: `http://localhost:5000/webhook` (POST only)

### Database Connections
- **PostgreSQL**: `localhost:5432` (trading_db/trader/SecureTrading2024)
- **Redis**: `localhost:6379` (SecureRedis2024)

### Monitoring Services
- **Grafana**: `http://localhost:3000` (admin/admin123)
- **Prometheus**: `http://localhost:9090`

### VNC Access
- **MT4**: `localhost:5901` (trading123)
- **MT5**: `localhost:5902` (trading123)

## ▶️ Quick Start Commands

### Start Everything
```bash
cd /home/eboalking/DEA/VPS-Docker
./start-all-services.sh
```

### Start Individual Components
```bash
# Start only MetaTrader 5
docker compose --profile mt5 up -d metatrader5

# Start monitoring services
docker compose --profile monitoring up -d grafana prometheus

# Start database services
docker compose --profile database up -d postgres
```

## 🧪 Testing Commands

### Webhook Server Tests
```bash
# Check if server is running
curl http://localhost:5000/health

# Check server status
curl http://localhost:5000/status

# Send a test BUY signal
curl -X POST http://localhost:5000/webhook \
  -H "Content-Type: application/json" \
  -d '{"action": "BUY", "symbol": "EURUSD", "lot_size": 0.1}'

# Send a test SELL signal with SL/TP
curl -X POST http://localhost:5000/webhook \
  -H "Content-Type: application/json" \
  -d '{"action": "SELL", "symbol": "GBPUSD", "lot_size": 0.2, "stop_loss": 50, "take_profit": 100}'
```

### Database Tests
```bash
# Test PostgreSQL connection
docker exec -it dea-postgres psql -U trader -d trading_db -c "SELECT version();"

# Test Redis connection
docker exec -it dea-redis redis-cli -a SecureRedis2024 ping
```

## 📊 Service Status Check

```bash
# Check which services are running
docker compose ps

# Check logs for specific services
docker compose logs webhook-server
docker compose logs metatrader5
```

## 🛑 Stop Services

```bash
# Stop all services
docker compose down

# Stop specific services
docker compose stop metatrader5
```

## 📁 Important File Locations

- **Main Configuration**: `/home/eboalking/DEA/VPS-Docker/.env`
- **Connection Settings**: `/home/eboalking/DEA/VPS-Docker/config/connections.conf`
- **Webhook Config**: `/home/eboalking/DEA/VPS-Docker/config/webhook.yaml`
- **MT4 Terminal**: `/home/eboalking/DEA/VPS-Docker/config/mt4/terminal.ini`
- **MT5 Terminal**: `/home/eboalking/DEA/VPS-Docker/config/mt5/terminal.ini`
- **Logs**: `/home/eboalking/DEA/VPS-Docker/logs/`

## 🔁 Configuration File Reload

After making changes to configuration files, restart the affected services:

```bash
# Restart webhook server after config changes
docker compose restart webhook-server

# Restart MT5 after terminal.ini changes
docker compose restart metatrader5
```

## 🆘 Troubleshooting Quick Fixes

1. **Webhook server not responding**:
   ```bash
   docker compose restart webhook-server
   ```

2. **MetaTrader container not starting**:
   ```bash
   docker compose logs metatrader5
   docker compose restart metatrader5
   ```

3. **Database connection issues**:
   ```bash
   docker compose restart postgres
   ```

4. **Monitoring services not accessible**:
   ```bash
   docker compose restart grafana prometheus
   ```

## 📞 Support Resources

- **Full Documentation**: [CONNECTIONS_README.md](CONNECTIONS_README.md)
- **Enhanced Guide**: [SETTINGS_README.md](SETTINGS_README.md)
- **Configuration Files**: `/home/eboalking/DEA/VPS-Docker/config/`
- **Logs Directory**: `/home/eboalking/DEA/VPS-Docker/logs/`