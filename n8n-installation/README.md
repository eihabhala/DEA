# 🚀 n8n Installation with SSL & DodoHook Integration
## Complete Setup Guide by Camlo Technologies

---

## 🎯 Overview

This guide provides complete instructions for installing **n8n** (workflow automation platform) with **SSL encryption** and **DodoHook webhook integration**. Perfect for professional trading automation and secure webhook processing.

---

## 📋 What You Get

### **🔧 n8n Features:**
- **Visual Workflow Builder** - Drag & drop automation
- **500+ Integrations** - Connect any service with APIs
- **Custom JavaScript Logic** - Advanced processing capabilities
- **Webhook Support** - Receive external triggers
- **Database Storage** - PostgreSQL for production use

### **🔐 SSL Security:**
- **Let's Encrypt Certificates** - Free SSL certificates
- **Automatic Renewal** - No manual certificate management
- **HTTPS Enforcement** - All traffic encrypted
- **Security Headers** - Protection against common attacks

### **🔗 DodoHook Integration:**
- **Dedicated Endpoints** - n8n-specific webhook URLs
- **Professional Infrastructure** - Replace ngrok limitations
- **Unlimited Processing** - No rate limits
- **Custom Domain Support** - Professional webhook URLs

---

## 🛠️ Installation Options

### **Option 1: Linux Installation with SSL (Recommended)**

#### **Prerequisites:**
- Ubuntu 20.04+ or similar Linux distribution
- Root or sudo access
- Domain name pointing to your server
- Ports 80, 443, and 5678 available

#### **Quick Installation:**
```bash
# Download and run the installation script
wget https://raw.githubusercontent.com/xnox-me/DEA/main/n8n-installation/install_n8n_ssl.sh
chmod +x install_n8n_ssl.sh

# Run with your domain
sudo ./install_n8n_ssl.sh n8n.yourtrading.com 5678 443 webhook.dodohook.com
```

#### **What the script does:**
1. ✅ Installs Node.js and npm
2. ✅ Installs n8n globally
3. ✅ Configures Nginx reverse proxy
4. ✅ Generates SSL certificates (Let's Encrypt or self-signed)
5. ✅ Creates systemd service for auto-start
6. ✅ Configures firewall rules
7. ✅ Sets up DodoHook integration
8. ✅ Creates management scripts

---

### **Option 2: Windows Installation**

#### **Prerequisites:**
- Windows 10/11 or Windows Server
- Administrator privileges
- Node.js 18+ installed

#### **Installation:**
```cmd
# Download and run the Windows installation script
install_n8n_windows.bat n8n.yourtrading.com 5678 webhook.dodohook.com
```

#### **Features:**
- ✅ Installs n8n with Windows configuration
- ✅ Creates startup scripts
- ✅ Configures Windows Firewall
- ✅ Sets up DodoHook integration
- ✅ Optional Windows Service setup

---

### **Option 3: Docker Deployment (Production)**

#### **Prerequisites:**
- Docker and Docker Compose installed
- Domain name and SSL certificates

#### **Quick Start:**
```bash
# Clone the configuration
git clone https://github.com/xnox-me/DEA.git
cd DEA/n8n-installation

# Configure your domain
nano docker-compose.yml
# Update: n8n.yourtrading.com to your domain

# Start all services
docker-compose up -d
```

#### **Included Services:**
- ✅ **n8n** - Main workflow automation platform
- ✅ **PostgreSQL** - Production database
- ✅ **Nginx** - Reverse proxy with SSL
- ✅ **Certbot** - Automatic SSL certificate management
- ✅ **DodoHook** - Webhook tunneling service

---

## 🔧 Configuration

### **n8n Configuration File:**
```json
{
  "host": "0.0.0.0",
  "port": 5678,
  "protocol": "https",
  "editorBaseUrl": "https://n8n.yourtrading.com",
  "webhookUrl": "https://n8n.yourtrading.com",
  "secureCookie": true,
  "timezone": "UTC",
  "payloadSizeMax": 16
}
```

### **DodoHook Integration:**
```yaml
# Webhook endpoints for n8n
n8n:
  enabled: true
  webhook_path: "/webhook/n8n"
  workflow_tracking: true
  enhanced_logging: true
  response_timeout: 60
```

---

## 🌐 Access & URLs

### **After Installation:**
- **n8n Interface**: `https://n8n.yourtrading.com`
- **DodoHook Webhooks**: `https://webhook.dodohook.com/webhook/n8n`
- **Health Check**: `https://n8n.yourtrading.com/health`

### **Workflow Webhooks:**
- **Generic**: `https://n8n.yourtrading.com/webhook/path`
- **With DodoHook**: `https://webhook.dodohook.com/webhook/n8n`
- **Workflow-specific**: `https://webhook.dodohook.com/webhook/n8n/trading-signals`

---

## 🔗 DodoHook Integration Setup

### **Step 1: Configure n8n Webhook Node**
1. Add a **Webhook** node to your workflow
2. Set **HTTP Method**: POST
3. Set **Path**: `trading-signals` (or your workflow name)
4. Set **Response**: JSON

### **Step 2: Use DodoHook URL**
Instead of the default n8n webhook URL, use:
```
https://webhook.dodohook.com/webhook/n8n/trading-signals
```

### **Step 3: Configure TradingView**
In TradingView alerts, use the DodoHook URL:
```json
{
  "action": "{{strategy.order.action}}",
  "symbol": "{{ticker}}",
  "price": "{{close}}",
  "platform": "n8n",
  "workflow": "trading-signals"
}
```

---

## 📊 Example Workflows

### **1. Trading Signal Router**
```
TradingView Alert → DodoHook → n8n → {
    ├── Risk Assessment
    ├── Position Sizing
    ├── MT4/MT5 Execution
    ├── Discord Notification
    └── Database Logging
}
```

### **2. Multi-Platform Distribution**
```
Signal Source → DodoHook → n8n → {
    ├── Multiple Brokers
    ├── Telegram Alerts
    ├── Email Notifications
    ├── Slack Messages
    └── Google Sheets Log
}
```

### **3. News-Based Trading**
```
RSS Feed → n8n → AI Analysis → Signal Generation → DodoHook → Trading Platform
```

---

## 🔧 Management Commands

### **Linux (systemd):**
```bash
# Check status
systemctl status n8n
systemctl status nginx

# Start/stop/restart
sudo systemctl start n8n
sudo systemctl stop n8n
sudo systemctl restart n8n

# View logs
journalctl -u n8n -f
tail -f /var/log/nginx/access.log
```

### **Docker:**
```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f n8n
docker-compose logs -f nginx

# Restart services
docker-compose restart n8n
docker-compose restart nginx
```

### **Windows:**
```cmd
# Start n8n
start_n8n.bat

# Check if running
tasklist | findstr node

# Stop n8n
# Press Ctrl+C in the n8n window
```

---

## 🛡️ Security Best Practices

### **SSL Configuration:**
- ✅ **TLS 1.2/1.3 Only** - Disable older protocols
- ✅ **Strong Ciphers** - Use modern encryption
- ✅ **HSTS Headers** - Force HTTPS connections
- ✅ **Certificate Pinning** - Prevent MITM attacks

### **Access Control:**
```nginx
# IP whitelisting example
location /webhook/ {
    allow 192.168.1.0/24;  # Your network
    allow 52.89.214.238;   # TradingView
    deny all;
    
    proxy_pass http://n8n;
}
```

### **Rate Limiting:**
```nginx
# Nginx rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=webhook:10m rate=100r/s;
```

---

## 📈 Performance Optimization

### **n8n Settings:**
```json
{
  "executions": {
    "timeout": 3600,
    "maxTimeout": 3600,
    "saveDataOnError": "all",
    "saveDataOnSuccess": "all",
    "saveDataManualExecutions": true
  },
  "nodes": {
    "exclude": [],
    "errorTriggerType": "n8n-nodes-base.errorTrigger"
  }
}
```

### **Database Optimization:**
```sql
-- PostgreSQL optimization
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
```

### **Nginx Optimization:**
```nginx
# Worker processes
worker_processes auto;
worker_connections 1024;

# Caching
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=n8n_cache:10m;
proxy_cache n8n_cache;
proxy_cache_valid 200 5m;
```

---

## 🔍 Troubleshooting

### **Common Issues:**

#### **n8n Won't Start:**
```bash
# Check logs
journalctl -u n8n -n 50

# Check configuration
n8n --version
node --version

# Check permissions
ls -la ~/.n8n/
```

#### **SSL Certificate Issues:**
```bash
# Check certificate
openssl x509 -in /etc/ssl/certs/n8n.crt -text -noout

# Renew Let's Encrypt
certbot renew --dry-run
```

#### **Webhook Not Working:**
```bash
# Test webhook directly
curl -X POST https://n8n.yourtrading.com/webhook/test \
     -H "Content-Type: application/json" \
     -d '{"test": "data"}'

# Check n8n logs
docker-compose logs -f n8n
```

#### **Database Connection Issues:**
```bash
# Check PostgreSQL
docker-compose exec postgres psql -U n8n -d n8n -c "\dt;"

# Check connection
docker-compose logs postgres
```

---

## 📚 Additional Resources

### **Documentation:**
- [n8n Official Docs](https://docs.n8n.io/)
- [DodoHook Integration Guide](../Webhook_Server/N8N_INTEGRATION_GUIDE.md)
- [Automation Platforms Guide](../Webhook_Server/AUTOMATION_PLATFORMS.md)

### **Community:**
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)
- [DodoHook Repository](https://github.com/xnox-me/DEA)

### **Professional Support:**
- **Email**: support@camlo.tech
- **Custom Setup**: Available for enterprise customers
- **Training**: n8n workflow development services

---

## 🎯 Quick Start Checklist

- [ ] Choose installation method (Linux/Windows/Docker)
- [ ] Prepare domain name and SSL certificates
- [ ] Run installation script
- [ ] Configure firewall and security
- [ ] Test n8n web interface
- [ ] Set up DodoHook integration
- [ ] Create first workflow with webhook
- [ ] Test webhook with TradingView
- [ ] Configure monitoring and backups

---

**🎉 You're ready to build powerful trading automation workflows with n8n and DodoHook!**

*Professional workflow automation meets enterprise-grade webhook infrastructure.*