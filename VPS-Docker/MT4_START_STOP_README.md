# DEA-MT4 Start/Stop Scripts

This directory contains dedicated scripts for starting and stopping only the MetaTrader 4 container of the DEA trading system.

## Scripts

### start-dea-mt4.sh
Starts only the MetaTrader 4 container along with its required dependencies:
- Redis (if not already running)
- Webhook Server (if not already running)

Usage:
```bash
./start-dea-mt4.sh
```

### stop-dea-mt4.sh
Stops only the MetaTrader 4 container.

Usage:
```bash
./stop-dea-mt4.sh
```

## Connection Information

After starting the MT4 container:
- VNC Access: localhost:5901 (password: trading123)
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