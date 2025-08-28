# DEA-MT5 Start/Stop Scripts

This directory contains dedicated scripts for starting and stopping only the MetaTrader 5 container of the DEA trading system.

## Scripts

### start-dea-mt5.sh
Starts only the MetaTrader 5 container along with its required dependencies:
- Redis (if not already running)
- Webhook Server (if not already running)

Usage:
```bash
./start-dea-mt5.sh
```

### stop-dea-mt5.sh
Stops only the MetaTrader 5 container.

Usage:
```bash
./stop-dea-mt5.sh
```

## Connection Information

After starting the MT5 container:
- VNC Access: localhost:5902 (password: trading123)
- Webhook Server: http://localhost:5000
- Health Check Endpoint: http://localhost:5000/health

## Prerequisites

- Docker must be installed and running
- Environment variables should be configured in the [.env](.env) file
- The full DEA system should be properly configured

## Notes

- These scripts automatically check for and start required dependencies
- The scripts will wait for services to initialize before proceeding
- Container status is displayed after operations