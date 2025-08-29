# 🛠️ Webhook Server Troubleshooting Guide

This guide helps diagnose and resolve common issues with the DEA trading system's webhook server.

## 📋 Common Issues and Solutions

### ❌ Failed to start Webhook Server - Port Already in Use

**Error Message:**
```
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint dea-webhook-server: address already in use
```

**Cause:**
Another process is already using port 5000, preventing the Docker container from binding to it.

**Solution:**
1. Check what's using port 5000:
   ```bash
   netstat -tlnp | grep :5000
   ```

2. Identify the process ID and stop it:
   ```bash
   # If it shows a process ID like 15277/python3
   kill 15277
   ```

3. Verify the port is free:
   ```bash
   netstat -tlnp | grep :5000
   # Should return no output
   ```

4. Start the webhook server:
   ```bash
   cd /home/eboalking/DEA/VPS-Docker
   docker compose up -d webhook-server
   ```

### ❌ Webhook Server Not Responding

**Symptoms:**
- `curl http://localhost:5000/health` returns connection refused
- Trading signals are not being processed

**Solution:**
1. Check if the container is running:
   ```bash
   cd /home/eboalking/DEA/VPS-Docker
   docker compose ps
   ```

2. If not running, start it:
   ```bash
   docker compose up -d webhook-server
   ```

3. Check container logs:
   ```bash
   docker compose logs webhook-server
   ```

4. If there are errors in the logs, restart the container:
   ```bash
   docker compose restart webhook-server
   ```

### ❌ Webhook Server Health Check Fails

**Symptoms:**
- `curl http://localhost:5000/health` returns an error or non-JSON response

**Solution:**
1. Check container status:
   ```bash
   docker compose ps webhook-server
   ```

2. Check logs for errors:
   ```bash
   docker compose logs webhook-server | tail -20
   ```

3. Restart if needed:
   ```bash
   docker compose restart webhook-server
   ```

### ❌ Method Not Allowed Errors

**Error Message:**
```
405 Method Not Allowed
```

**Cause:**
Using the wrong HTTP method for an endpoint.

**Solution:**
- `/health`: Use GET method
- `/status`: Use GET method
- `/webhook`: Use POST method

**Correct usage:**
```bash
# ✅ Correct
curl -X GET http://localhost:5000/health
curl -X GET http://localhost:5000/status
curl -X POST http://localhost:5000/webhook -H "Content-Type: application/json" -d '{"action":"BUY","symbol":"EURUSD","lot_size":0.1}'

# ❌ Incorrect
curl -X GET http://localhost:5000/webhook  # Will return 405 error
```

### ❌ 404 Not Found Errors

**Error Message:**
```
404 Not Found
```

**Cause:**
Trying to access a non-existent endpoint.

**Solution:**
The webhook server only has three endpoints:
- `GET /health` - Server health check
- `GET /status` - Server status information
- `POST /webhook` - Trading signal processing

There is no root endpoint (`/`), so accessing `http://localhost:5000/` will return 404.

## 🔧 Diagnostic Commands

### Check Service Status
```bash
cd /home/eboalking/DEA/VPS-Docker
docker compose ps
```

### Check Service Logs
```bash
# Check recent logs
docker compose logs webhook-server | tail -20

# Check logs with timestamps
docker compose logs --timestamps webhook-server | tail -20

# Follow logs in real-time
docker compose logs -f webhook-server
```

### Test Service Endpoints
```bash
# Health check
curl -s http://localhost:5000/health

# Status check
curl -s http://localhost:5000/status

# Send test signal
curl -s -X POST http://localhost:5000/webhook \
  -H "Content-Type: application/json" \
  -d '{"action": "BUY", "symbol": "EURUSD", "lot_size": 0.1}'
```

### Check Port Usage
```bash
# Check what's using port 5000
netstat -tlnp | grep :5000

# Check all listening ports
netstat -tlnp
```

## 🔄 Restart Procedures

### Soft Restart
```bash
cd /home/eboalking/DEA/VPS-Docker
docker compose restart webhook-server
```

### Hard Restart
```bash
cd /home/eboalking/DEA/VPS-Docker
docker compose stop webhook-server
docker compose rm webhook-server
docker compose up -d webhook-server
```

## ⚠️ Prevention Tips

1. **Always check for running processes before starting Docker containers:**
   ```bash
   netstat -tlnp | grep :5000
   ```

2. **Use the start-all-services.sh script for consistent startup:**
   ```bash
   cd /home/eboalking/DEA/VPS-Docker
   ./start-all-services.sh
   ```

3. **Check logs regularly for issues:**
   ```bash
   docker compose logs webhook-server | tail -10
   ```

4. **Monitor service health with the health endpoint:**
   ```bash
   curl -s http://localhost:5000/health
   ```

## 📞 Support

If you continue to experience issues:

1. Check logs in `/home/eboalking/DEA/VPS-Docker/logs/`
2. Review configuration files in `/home/eboalking/DEA/VPS-Docker/config/`
3. Ensure all dependencies (Redis) are running before starting the webhook server
4. Contact support with error messages and logs