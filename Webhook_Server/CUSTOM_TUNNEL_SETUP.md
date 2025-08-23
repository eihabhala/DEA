# Custom Webhook Tunnel Server Setup Guide

## 🎯 Overview

This custom tunnel server replaces ngrok and provides you with complete control over your webhook tunneling infrastructure. It's specifically designed for trading applications and TradingView webhooks.

## ✨ Advantages Over ngrok

### 🚀 **Performance Benefits**
- **No Rate Limits** - Unlimited webhook requests
- **Lower Latency** - Direct connection without third-party routing
- **Better Reliability** - No dependency on external services
- **Custom Caching** - Optimize for your specific trading patterns

### 🔒 **Security Benefits**
- **Private Infrastructure** - Complete control over your data
- **Custom Authentication** - Implement your own security measures
- **IP Whitelisting** - Restrict access to specific sources
- **SSL/TLS Control** - Use your own certificates

### 💰 **Cost Benefits**
- **No Subscription Fees** - One-time setup, no recurring costs
- **Scalable** - Handle thousands of webhooks without extra charges
- **Customizable** - Add features specific to your trading needs

## 🛠️ Installation & Setup

### Step 1: Install Dependencies

```bash
# Install Python dependencies
pip3 install -r requirements_tunnel.txt

# Or install manually
pip3 install aiohttp pyyaml cryptography
```

### Step 2: Configure Your Domain

1. **Get a Domain** (if you don't have one):
   - Register a domain from any provider (GoDaddy, Namecheap, etc.)
   - Or use a subdomain from an existing domain

2. **Configure DNS**:
   ```
   A Record: webhook.yourtrading.com → YOUR_SERVER_IP
   ```

3. **Update Configuration**:
   Edit `tunnel_config.yaml`:
   ```yaml
   server:
     domain: webhook.yourtrading.com  # Your domain here
     port: 443                       # HTTPS port
   ```

### Step 3: Generate SSL Certificates

#### Option A: Self-Signed (Quick Setup)
```bash
./generate_ssl.sh webhook.yourtrading.com
```

#### Option B: Let's Encrypt (Production)
```bash
# Install certbot
sudo apt install certbot

# Get free SSL certificate
sudo certbot certonly --standalone -d webhook.yourtrading.com

# Update config to use Let's Encrypt certificates
# ssl_cert: /etc/letsencrypt/live/webhook.yourtrading.com/fullchain.pem
# ssl_key: /etc/letsencrypt/live/webhook.yourtrading.com/privkey.pem
```

### Step 4: Configure Firewall

```bash
# Allow HTTPS traffic
sudo ufw allow 443/tcp

# Allow HTTP (optional, for redirects)
sudo ufw allow 80/tcp

# Enable firewall
sudo ufw enable
```

### Step 5: Start the Server

```bash
# Quick start (development)
./start_custom_tunnel.sh

# Or start manually
python3 custom_tunnel_server.py
```

## 🔧 Configuration Options

### Basic Configuration (`tunnel_config.yaml`)

```yaml
server:
  host: 0.0.0.0                    # Listen on all interfaces
  port: 443                        # HTTPS port
  domain: webhook.yourtrading.com   # Your domain
  ssl_cert: certs/server.crt        # SSL certificate
  ssl_key: certs/server.key         # SSL private key

tunnel:
  local_host: 127.0.0.1            # Local webhook server
  local_port: 5000                 # Local webhook port
  auth_token: your-secret-token     # Authentication token
  max_connections: 100             # Max concurrent connections
  timeout: 30                      # Request timeout

security:
  allowed_ips: []                  # IP whitelist (empty = allow all)
  rate_limit: 1000                 # Requests per hour per IP
  require_auth: false              # Token authentication

logging:
  level: INFO                      # Log level
  file: tunnel_server.log          # Log file
```

### Advanced Security Configuration

```yaml
security:
  # Restrict to TradingView IPs only
  allowed_ips:
    - 52.89.214.238
    - 34.212.75.30
    - 54.218.53.128
    # Add more TradingView IPs as needed
  
  # Enable authentication
  require_auth: true
  
  # Custom rate limiting
  rate_limit: 500                  # Lower limit for higher security
```

## 🌐 Usage

### TradingView Setup

1. **Alert Configuration**:
   - Webhook URL: `https://webhook.yourtrading.com/webhook`
   - Message: `{"action":"{{strategy.order.action}}","symbol":"{{ticker}}","price":"{{close}}"}`

2. **With Authentication** (if enabled):
   - Add header: `Authorization: Bearer your-secret-token`

### Dashboard Access

- **Dashboard**: `https://webhook.yourtrading.com/dashboard`
- **Status API**: `https://webhook.yourtrading.com/status`
- **Health Check**: `https://webhook.yourtrading.com/health`

## 📊 Monitoring & Maintenance

### Health Monitoring

```bash
# Check server status
curl https://webhook.yourtrading.com/health

# Get detailed statistics
curl https://webhook.yourtrading.com/stats
```

### Log Monitoring

```bash
# Monitor real-time logs
tail -f tunnel_server.log

# Check for errors
grep ERROR tunnel_server.log

# Monitor requests
grep "Forwarded" tunnel_server.log
```

### Performance Optimization

1. **Enable Compression**:
   ```yaml
   advanced:
     enable_compression: true
   ```

2. **Monitor Resource Usage**:
   ```bash
   # Check memory usage
   ps aux | grep custom_tunnel_server
   
   # Check network connections
   netstat -an | grep :443
   ```

## 🔄 Production Deployment

### Using systemd (Recommended)

1. **Create Service File**:
   ```bash
   sudo nano /etc/systemd/system/tunnel-server.service
   ```

2. **Service Configuration**:
   ```ini
   [Unit]
   Description=Custom Webhook Tunnel Server
   After=network.target
   
   [Service]
   Type=simple
   User=yourusername
   WorkingDirectory=/path/to/webhook/server
   ExecStart=/usr/bin/python3 custom_tunnel_server.py
   Restart=always
   RestartSec=10
   
   [Install]
   WantedBy=multi-user.target
   ```

3. **Enable and Start**:
   ```bash
   sudo systemctl enable tunnel-server
   sudo systemctl start tunnel-server
   sudo systemctl status tunnel-server
   ```

### Auto-renewal for Let's Encrypt

```bash
# Add to crontab
sudo crontab -e

# Add line for automatic renewal
0 2 * * * certbot renew --quiet && systemctl reload tunnel-server
```

## 🚨 Troubleshooting

### Common Issues

1. **Port Already in Use**:
   ```bash
   # Check what's using port 443
   sudo netstat -tlnp | grep :443
   
   # Kill the process or change port in config
   ```

2. **SSL Certificate Issues**:
   ```bash
   # Test certificate
   openssl x509 -in certs/server.crt -text -noout
   
   # Regenerate if needed
   ./generate_ssl.sh
   ```

3. **Permission Denied**:
   ```bash
   # For ports < 1024, you need root or capabilities
   sudo setcap 'cap_net_bind_service=+ep' /usr/bin/python3
   ```

4. **Local Server Connection**:
   ```bash
   # Check if local webhook server is running
   curl http://localhost:5000/health
   
   # Start if needed
   python3 webhook_server.py &
   ```

### Debug Mode

Enable debug logging in `tunnel_config.yaml`:
```yaml
logging:
  level: DEBUG
```

## 🎯 Benefits Summary

✅ **Complete Control** - Your infrastructure, your rules  
✅ **No Rate Limits** - Handle unlimited webhook traffic  
✅ **Better Security** - Private data, custom authentication  
✅ **Lower Costs** - No monthly subscription fees  
✅ **Higher Performance** - Direct routing, lower latency  
✅ **Custom Features** - Add trading-specific functionality  
✅ **Better Reliability** - No dependency on third-party services  

## 📞 Support

For issues with the custom tunnel server:
1. Check the logs: `tail -f tunnel_server.log`
2. Verify configuration: `python3 -c "import yaml; print(yaml.safe_load(open('tunnel_config.yaml')))"`
3. Test connectivity: `curl -v https://webhook.yourtrading.com/health`

Your custom tunnel server is now ready to replace ngrok! 🚀