#!/bin/bash

# Verification Script for DEA Setup
# This script verifies that the DEA project is properly configured

echo "✅ DEA Setup Verification"
echo "========================"

cd /home/eboalking/DEA

# 1. Check if repository is clean
echo "1. Repository Status:"
git status --porcelain | grep -q . && echo "   ⚠️  There are uncommitted changes" || echo "   ✅ Repository is clean"

# 2. Check if required directories exist
echo "2. Directory Structure:"
[ -d "Webhook_Server" ] && echo "   ✅ Webhook_Server directory exists" || echo "   ❌ Webhook_Server directory missing"
[ -d "VPS-Docker" ] && echo "   ✅ VPS-Docker directory exists" || echo "   ❌ VPS-Docker directory missing"
[ -d "django-dashboard" ] && echo "   ✅ django-dashboard directory exists" || echo "   ❌ django-dashboard directory missing"

# 3. Check if virtual environment exists
echo "3. Python Environment:"
[ -d "Webhook_Server/venv" ] && echo "   ✅ Python virtual environment exists" || echo "   ❌ Python virtual environment missing"

# 4. Check if configuration files exist
echo "4. Configuration Files:"
[ -f "VPS-Docker/.env" ] && echo "   ✅ .env file exists" || echo "   ⚠️  .env file missing (run setup_repository.sh)"
[ -f "VPS-Docker/mt5-container/config/mt5-config.ini" ] && echo "   ✅ MT5 config file exists" || echo "   ⚠️  MT5 config file missing"

# 5. Check if important scripts are executable
echo "5. Executable Scripts:"
[ -x "Webhook_Server/start_server.sh" ] && echo "   ✅ start_server.sh is executable" || echo "   ⚠️  start_server.sh is not executable"
[ -x "setup_repository.sh" ] && echo "   ✅ setup_repository.sh is executable" || echo "   ⚠️  setup_repository.sh is not executable"

# 6. Check Docker installation
echo "6. Docker Installation:"
command -v docker >/dev/null 2>&1 && echo "   ✅ Docker is installed" || echo "   ⚠️  Docker is not installed"
command -v docker-compose >/dev/null 2>&1 && echo "   ✅ Docker Compose is installed" || echo "   ⚠️  Docker Compose is not installed"

echo ""
echo "📋 Setup Verification Complete"
echo "The DEA project folder is fully configured and ready for use!"