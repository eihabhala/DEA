#!/bin/bash

# DodoHook Integration Setup for Existing n8n Installation
# by Camlo Technologies

echo "🔗 DodoHook Integration Setup for n8n"
echo "by Camlo Technologies"
echo "======================================"
echo ""

# Configuration
N8N_DOMAIN=${1:-"n8n.yourtrading.com"}
DODOHOOK_DOMAIN=${2:-"webhook.dodohook.com"}
N8N_DATA_DIR=${3:-"$HOME/.n8n"}

echo "📋 Configuration:"
echo "  n8n Domain: $N8N_DOMAIN"
echo "  DodoHook Domain: $DODOHOOK_DOMAIN"
echo "  n8n Data Directory: $N8N_DATA_DIR"
echo ""

# Check if n8n is installed
if ! command -v n8n &> /dev/null; then
    echo "❌ n8n is not installed or not in PATH"
    echo "Please install n8n first:"
    echo "  npm install -g n8n"
    exit 1
fi

echo "✅ n8n found: $(n8n --version)"

# Check if n8n data directory exists
if [ ! -d "$N8N_DATA_DIR" ]; then
    echo "⚠️  n8n data directory not found: $N8N_DATA_DIR"
    echo "Creating directory..."
    mkdir -p "$N8N_DATA_DIR"
fi

# Create DodoHook configuration file
echo "🔧 Creating DodoHook configuration..."
cat > "$N8N_DATA_DIR/dodohook_config.json" << EOF
{
  "dodohook": {
    "enabled": true,
    "domain": "$DODOHOOK_DOMAIN",
    "endpoints": {
      "main": "https://$DODOHOOK_DOMAIN/webhook/n8n",
      "workflow_specific": "https://$DODOHOOK_DOMAIN/webhook/n8n/{workflow-id}"
    },
    "features": {
      "enhanced_logging": true,
      "workflow_tracking": true,
      "response_timeout": 60,
      "retry_failed_requests": true
    }
  },
  "n8n_integration": {
    "domain": "$N8N_DOMAIN",
    "webhook_base_url": "https://$N8N_DOMAIN/webhook",
    "editor_url": "https://$N8N_DOMAIN"
  }
}
EOF

echo "✅ DodoHook configuration created: $N8N_DATA_DIR/dodohook_config.json"

# Create workflow templates
echo "📝 Creating workflow templates..."
mkdir -p "$N8N_DATA_DIR/templates/dodohook"

# Trading Signal Router Template
cat > "$N8N_DATA_DIR/templates/dodohook/trading_signal_router.json" << 'EOF'
{
  "name": "Trading Signal Router with DodoHook",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "trading-signals",
        "responseMode": "responseNode",
        "options": {}
      },
      "name": "DodoHook Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [240, 300],
      "webhookId": "trading-signals"
    },
    {
      "parameters": {
        "functionCode": "// DodoHook Trading Signal Processor\n// Enhanced signal validation and processing\n\nconst signal = $json.body;\n\n// Validate required fields\nif (!signal.action || !signal.symbol) {\n  throw new Error('Invalid signal: missing action or symbol');\n}\n\n// Enhanced signal with metadata\nconst processedSignal = {\n  ...signal,\n  timestamp: new Date().toISOString(),\n  processed_by: 'n8n',\n  source: 'dodohook',\n  workflow_id: 'trading-signals',\n  validation: {\n    action_valid: ['BUY', 'SELL', 'CLOSE'].includes(signal.action),\n    symbol_format: /^[A-Z]{6}$/.test(signal.symbol),\n    price_valid: signal.price && signal.price > 0\n  }\n};\n\n// Calculate risk score\nprocessedSignal.risk_score = calculateRiskScore(signal);\n\n// Add position sizing recommendation\nprocessedSignal.position_size = calculatePositionSize(processedSignal.risk_score);\n\nreturn processedSignal;\n\nfunction calculateRiskScore(signal) {\n  const riskMap = {\n    'EURUSD': 0.2, 'GBPUSD': 0.3, 'USDJPY': 0.25,\n    'AUDUSD': 0.3, 'USDCAD': 0.25, 'USDCHF': 0.25,\n    'XAUUSD': 0.5, 'XAGUSD': 0.4,\n    'BTCUSD': 0.8, 'ETHUSD': 0.7\n  };\n  return riskMap[signal.symbol] || 0.4;\n}\n\nfunction calculatePositionSize(riskScore) {\n  const maxRisk = 0.02; // 2% account risk\n  return Math.min(maxRisk / riskScore, 1.0);\n}"
      },
      "name": "Process Signal",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [460, 300]
    },
    {
      "parameters": {
        "conditions": {
          "boolean": [
            {
              "value1": "={{$json.validation.action_valid}}",
              "value2": true
            },
            {
              "value1": "={{$json.validation.symbol_format}}",
              "value2": true
            }
          ]
        }
      },
      "name": "Risk Check",
      "type": "n8n-nodes-base.if",
      "typeVersion": 1,
      "position": [680, 300]
    },
    {
      "parameters": {
        "functionCode": "// Send success response back to DodoHook\nreturn {\n  status: 'success',\n  message: 'Signal processed successfully',\n  signal_id: $json.timestamp,\n  processed_by: 'n8n-dodohook',\n  webhook_source: 'trading-signals'\n};"
      },
      "name": "Success Response",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [900, 200]
    },
    {
      "parameters": {
        "functionCode": "// Send error response back to DodoHook\nreturn {\n  status: 'error',\n  message: 'Signal validation failed',\n  errors: $json.validation,\n  processed_by: 'n8n-dodohook'\n};"
      },
      "name": "Error Response",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [900, 400]
    }
  ],
  "connections": {
    "DodoHook Webhook": {
      "main": [
        [
          {
            "node": "Process Signal",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Process Signal": {
      "main": [
        [
          {
            "node": "Risk Check",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Risk Check": {
      "main": [
        [
          {
            "node": "Success Response",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Error Response",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
EOF

echo "✅ Trading signal router template created"

# Multi-Platform Distribution Template
cat > "$N8N_DATA_DIR/templates/dodohook/multi_platform_distribution.json" << 'EOF'
{
  "name": "Multi-Platform Signal Distribution",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "distribute-signals",
        "responseMode": "responseNode"
      },
      "name": "DodoHook Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [240, 300]
    },
    {
      "parameters": {
        "functionCode": "// Multi-platform signal distribution\nconst signal = $json.body;\n\n// Create platform-specific signals\nconst platforms = [\n  { name: 'discord', enabled: true },\n  { name: 'telegram', enabled: true },\n  { name: 'email', enabled: true },\n  { name: 'mt4', enabled: true },\n  { name: 'database', enabled: true }\n];\n\nreturn platforms.map(platform => ({\n  ...signal,\n  platform: platform.name,\n  enabled: platform.enabled,\n  timestamp: new Date().toISOString()\n}));"
      },
      "name": "Split to Platforms",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [460, 300]
    }
  ]
}
EOF

echo "✅ Multi-platform distribution template created"

# Create integration helper script
cat > "$N8N_DATA_DIR/dodohook_helper.sh" << 'HELPER_EOF'
#!/bin/bash

# DodoHook Integration Helper for n8n
# Quick commands for managing DodoHook integration

DODOHOOK_DOMAIN="webhook.dodohook.com"
N8N_DOMAIN="n8n.yourtrading.com"

case "$1" in
    "urls")
        echo "🔗 DodoHook Webhook URLs:"
        echo "  Main: https://$DODOHOOK_DOMAIN/webhook/n8n"
        echo "  Trading Signals: https://$DODOHOOK_DOMAIN/webhook/n8n/trading-signals"
        echo "  Distribution: https://$DODOHOOK_DOMAIN/webhook/n8n/distribute-signals"
        echo ""
        echo "📊 n8n URLs:"
        echo "  Editor: https://$N8N_DOMAIN"
        echo "  Health: https://$N8N_DOMAIN/health"
        ;;
    "test")
        echo "🧪 Testing DodoHook webhook..."
        curl -X POST "https://$DODOHOOK_DOMAIN/webhook/n8n" \
             -H "Content-Type: application/json" \
             -d '{"action":"BUY","symbol":"EURUSD","price":1.0500,"test":true}'
        ;;
    "status")
        echo "📊 Checking DodoHook status..."
        curl -s "https://$DODOHOOK_DOMAIN/status" | jq .
        ;;
    "templates")
        echo "📝 Available workflow templates:"
        ls -la "$HOME/.n8n/templates/dodohook/"
        ;;
    *)
        echo "DodoHook Integration Helper"
        echo "Usage: $0 {urls|test|status|templates}"
        echo ""
        echo "Commands:"
        echo "  urls      - Show webhook URLs"
        echo "  test      - Test webhook connection"
        echo "  status    - Check DodoHook status"
        echo "  templates - List workflow templates"
        ;;
esac
HELPER_EOF

chmod +x "$N8N_DATA_DIR/dodohook_helper.sh"
echo "✅ Helper script created: $N8N_DATA_DIR/dodohook_helper.sh"

# Create environment file for n8n
echo "⚙️  Creating n8n environment configuration..."
cat > "$N8N_DATA_DIR/.env" << EOF
# DodoHook Integration Environment
DODOHOOK_DOMAIN=$DODOHOOK_DOMAIN
DODOHOOK_WEBHOOK_URL=https://$DODOHOOK_DOMAIN/webhook/n8n
N8N_DOMAIN=$N8N_DOMAIN

# Enhanced n8n settings for DodoHook
N8N_WEBHOOK_URL=https://$N8N_DOMAIN
N8N_EDITOR_BASE_URL=https://$N8N_DOMAIN
N8N_PROTOCOL=https
N8N_SECURE_COOKIE=true
N8N_PAYLOAD_SIZE_MAX=16

# Performance settings for webhook processing
NODE_OPTIONS=--max-old-space-size=4096
N8N_EXECUTIONS_TIMEOUT=3600
N8N_EXECUTIONS_TIMEOUT_MAX=3600
EOF

echo "✅ Environment configuration created: $N8N_DATA_DIR/.env"

# Display integration information
echo ""
echo "🎉 DodoHook Integration Setup Complete!"
echo "======================================"
echo ""
echo "📋 Configuration Files Created:"
echo "  Config: $N8N_DATA_DIR/dodohook_config.json"
echo "  Environment: $N8N_DATA_DIR/.env"
echo "  Helper: $N8N_DATA_DIR/dodohook_helper.sh"
echo ""
echo "📝 Workflow Templates:"
echo "  Trading Router: $N8N_DATA_DIR/templates/dodohook/trading_signal_router.json"
echo "  Multi-Platform: $N8N_DATA_DIR/templates/dodohook/multi_platform_distribution.json"
echo ""
echo "🔗 DodoHook Webhook URLs:"
echo "  Main: https://$DODOHOOK_DOMAIN/webhook/n8n"
echo "  Trading Signals: https://$DODOHOOK_DOMAIN/webhook/n8n/trading-signals"
echo "  Distribution: https://$DODOHOOK_DOMAIN/webhook/n8n/distribute-signals"
echo ""
echo "🎯 Next Steps:"
echo "  1. Import workflow templates in n8n editor"
echo "  2. Configure your webhook nodes with DodoHook URLs"
echo "  3. Test webhook integration: $N8N_DATA_DIR/dodohook_helper.sh test"
echo "  4. Start creating your trading automation workflows"
echo ""
echo "📚 Documentation:"
echo "  DodoHook Guide: https://github.com/xnox-me/DEA/blob/main/Webhook_Server/N8N_INTEGRATION_GUIDE.md"
echo "  n8n Docs: https://docs.n8n.io"
echo ""
echo "✅ Integration ready for use!"