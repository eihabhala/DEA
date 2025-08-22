# 🤖 AI Trading Expert Advisor

[![License](https://img.shields.io/badge/License-Private-red.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-MT4%2FMT5-blue.svg)](https://www.metatrader4.com/)
[![Language](https://img.shields.io/badge/Language-MQL4%2FMQL5-green.svg)](https://www.mql5.com/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-yellow.svg)](https://python.org/)

> **Advanced MetaTrader Expert Advisor with AI-Powered Analysis, ATR Channel Strategy, and TradingView Webhook Integration**

## 🚀 **Quick Start**

### Prerequisites
- MetaTrader 4 or MetaTrader 5
- Python 3.8+ (for webhook server)
- Windows 10/11 or Windows Server

### Installation
```bash
# 1. Clone the repository
git clone https://github.com/yourusername/ai-trading-expert.git
cd ai-trading-expert

# 2. Install Python dependencies
cd Webhook_Server
pip install -r requirements.txt

# 3. Copy EA files to MetaTrader
# Copy MQL4/MQL5 files to your MetaTrader data directory
```

### Quick Setup
1. Load `AI_Trading_Expert.ex4` or `AI_Trading_Expert.ex5` on your chart
2. Configure parameters (see [Configuration Guide](Documentation/README.md))
3. Start webhook server: `Webhook_Server/start_server.bat`
4. Enable AutoTrading in MetaTrader

## ✨ **Key Features**

### 🧠 **AI-Powered Analysis**
- **Real-time News Analysis**: Fetches and analyzes financial news using advanced NLP
- **Social Media Sentiment**: Monitors social platforms for market sentiment
- **Market Impact Assessment**: AI-driven evaluation of news impact on currency pairs
- **Confidence Scoring**: Machine learning confidence levels for trading decisions

### 📊 **ATR Channel Strategy**
- **Dynamic Support/Resistance**: Volatility-adaptive channel trading
- **Breakout Signals**: Momentum-based entry signals
- **Reversal Signals**: Mean reversion trading opportunities
- **Risk-Adjusted Sizing**: Automatic position sizing based on volatility

### 🎨 **Professional Dashboard**
- **Real-time Status Display**: Live EA status and market conditions
- **AI Analysis Panel**: Sentiment scores, recommendations, confidence levels
- **ATR Channel Visualization**: Live channel data and position tracking
- **Interactive Controls**: Manual trading controls and system management

### 🔗 **Advanced Integration**
- **TradingView Webhooks**: Direct signal reception from TradingView alerts
- **Multi-Platform Signals**: Compatible with various signal providers
- **Python Server**: Robust webhook processing with error handling
- **Real-time Processing**: Instant signal execution with minimal latency

### 🛡️ **Enterprise Risk Management**
- **Position Sizing**: Risk-based and fixed lot sizing options
- **Drawdown Protection**: Maximum drawdown limits with automatic reduction
- **Multi-Position Management**: Intelligent handling of concurrent trades
- **Stop Loss/Take Profit**: Dynamic SL/TP based on market conditions

## 📁 **Repository Structure**

```
AI_Expert_Advisor/
├── 📄 README.md                          # This file
├── 📄 PROJECT_SUMMARY.md                 # Detailed project overview
├── 📄 FIXES_APPLIED.md                   # Recent fixes and updates
├── 📄 .gitignore                         # Git ignore rules
├── 📁 MQL4/
│   └── 🔧 AI_Trading_Expert.mq4          # MetaTrader 4 Expert Advisor
├── 📁 MQL5/
│   └── 🔧 AI_Trading_Expert.mq5          # MetaTrader 5 Expert Advisor
├── 📁 Include/                           # Shared library modules
│   ├── 📁 AI_Engine/
│   │   ├── 🧠 NewsAnalyzer.mqh          # AI news analysis engine
│   │   └── 📱 SocialSentiment.mqh       # Social media sentiment analyzer
│   ├── 📁 Risk_Management/
│   │   └── 🛡️ RiskManager.mqh           # Comprehensive risk management
│   ├── 📁 Utils/
│   │   ├── 📊 ATRChannel.mqh            # ATR Channel strategy implementation
│   │   ├── 🔗 WebhookHandler.mqh        # Webhook signal processing
│   │   └── 📝 Logger.mqh                # Advanced logging system
│   └── 📁 Visual_Components/
│       └── 🎨 Dashboard.mqh             # Professional visual interface
├── 📁 Webhook_Server/                    # Python webhook server
│   ├── 🐍 webhook_server.py             # Main server implementation
│   ├── 📋 requirements.txt              # Python dependencies
│   └── 🚀 start_server.bat              # Windows startup script
├── 📁 Config/
│   └── ⚙️ EA_Configuration_Template.mqh  # Configuration template
└── 📁 Documentation/                     # Comprehensive documentation
    ├── 📖 README.md                     # Installation and usage guide
    └── 📊 ATR_Channel_Strategy.md       # ATR Channel strategy documentation
```

## ⚙️ **Configuration**

### Basic Settings
```mql4
// Core EA Settings
input bool      InpEnableTrading = true;           // Enable live trading
input bool      InpEnableAIAnalysis = true;        // Enable AI analysis
input bool      InpEnableATRChannel = true;        // Enable ATR Channel strategy
input bool      InpEnableWebhooks = true;          // Enable webhook signals

// Trading Parameters
input double    InpLotSize = 0.1;                  // Base lot size
input double    InpRiskPercent = 2.0;               // Risk per trade %
input int       InpMaxPositions = 5;               // Maximum positions
```

### ATR Channel Configuration
```mql4
// ATR Channel Strategy
input int       InpATRPeriod = 14;                 // ATR calculation period
input double    InpATRMultiplier = 2.0;            // Channel width multiplier
input bool      InpATRUseBreakout = true;          // Enable breakout signals
input bool      InpATRUseReversal = false;         // Enable reversal signals
```

## 🔗 **TradingView Integration**

### Webhook Setup
1. Create TradingView alert
2. Set webhook URL: `http://your-server:8080/webhook`
3. Use JSON message format:

```json
{
    "action": "{{strategy.order.action}}",
    "symbol": "{{ticker}}",
    "price": "{{close}}",
    "source": "TradingView",
    "lot_size": 0.1,
    "comment": "TradingView Signal"
}
```

### Supported Actions
- `BUY`: Open long position
- `SELL`: Open short position  
- `CLOSE`: Close positions
- `CLOSE_ALL`: Close all positions

## 📊 **Performance Features**

### AI Analysis Metrics
- **Sentiment Score**: -1.0 to 1.0 (bearish to bullish)
- **Confidence Level**: 0-100% AI confidence
- **Risk Score**: 0-1.0 volatility and risk assessment
- **Price Target**: AI-calculated target levels

### ATR Channel Metrics
- **Channel Width**: Current volatility-based channel size
- **Signal Strength**: Breakout/reversal signal intensity
- **Position Relative to Channel**: Above/Below/Inside channel
- **Volatility Forecast**: Expected market volatility

## 🛠️ **Development**

### Building from Source
```bash
# Compile MT4 version
# Copy MQL4/AI_Trading_Expert.mq4 to MetaTrader 4 Experts folder
# Compile in MetaEditor

# Compile MT5 version  
# Copy MQL5/AI_Trading_Expert.mq5 to MetaTrader 5 Experts folder
# Compile in MetaEditor
```

### Testing
1. **Demo Account**: Always test on demo first
2. **Backtesting**: Use MetaTrader Strategy Tester
3. **Paper Trading**: Monitor signals without execution
4. **Gradual Deployment**: Start with small position sizes

## 🔒 **Security & Risk**

### Security Features
- **Input Validation**: All webhook signals validated
- **Authentication**: Optional webhook token authentication
- **IP Whitelisting**: Restrict webhook access by IP
- **Error Handling**: Comprehensive error recovery

### Risk Management
- **Position Limits**: Maximum concurrent positions
- **Drawdown Protection**: Automatic position reduction
- **Volatility Adjustment**: Dynamic risk based on market conditions
- **Emergency Stops**: Manual and automatic position closure

## 📈 **Performance Monitoring**

### Logging Features
- **Trade Execution**: Complete trade history
- **AI Decisions**: All AI analysis results
- **Signal Processing**: Webhook signal handling
- **Error Tracking**: Detailed error logs
- **Performance Metrics**: Win rates and risk metrics

### Dashboard Monitoring
- **Real-time Status**: Live EA and market status
- **AI Analysis**: Current sentiment and recommendations
- **ATR Channel**: Live channel data and signals
- **Position Tracking**: Open positions and P&L

## 🚨 **Important Disclaimers**

### Risk Warning
> **⚠️ HIGH RISK WARNING**: Trading foreign exchange and CFDs involves significant risk and may result in the loss of your invested capital. You should not invest more than you can afford to lose and should ensure that you fully understand the risks involved.

### Usage Guidelines
- **Demo Testing**: Always test thoroughly on demo accounts
- **Risk Management**: Never risk more than you can afford to lose
- **Market Conditions**: Adapt parameters to current market conditions
- **Supervision**: Maintain oversight of automated trading
- **Updates**: Keep EA updated with latest fixes and improvements

## 📞 **Support & Contributing**

### Getting Help
1. **Documentation**: Check comprehensive docs in `/Documentation/`
2. **Log Files**: Review EA log files for error details
3. **Demo Testing**: Test all features on demo account first
4. **Issue Reporting**: Use GitHub issues for bug reports

### Contributing
1. **Fork Repository**: Create your feature branch
2. **Test Changes**: Thoroughly test all modifications
3. **Documentation**: Update docs for new features
4. **Pull Request**: Submit PR with detailed description

## 📄 **License**

This project is private and proprietary. All rights reserved.

---

**Version**: 1.0  
**Last Updated**: 2024  
**Compatibility**: MT4/MT5  
**Platform**: Windows  
**Language**: MQL4/MQL5, Python  

🚀 **Ready to revolutionize your trading with AI-powered automation!**