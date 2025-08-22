# AI Trading Expert Advisor
## Advanced MetaTrader EA with AI-Powered Analysis & Webhook Integration

### 🚀 Features

- **AI-Powered News Analysis**: Real-time fundamental analysis using advanced sentiment analysis
- **Social Media Sentiment**: Track market sentiment from social platforms
- **TradingView Webhook Integration**: Receive and execute signals from TradingView and other platforms
- **Beautiful Visual Dashboard**: Professional interface with real-time information display
- **Advanced Risk Management**: Comprehensive position sizing and risk controls
- **Multi-Platform Support**: Compatible with both MT4 and MT5
- **Comprehensive Logging**: Detailed trade and analysis logging
- **Real-time AI Recommendations**: Get AI-powered trading recommendations

### 📋 System Requirements

- MetaTrader 4 or MetaTrader 5
- Windows 10/11 or Windows Server
- Internet connection for news and social sentiment analysis
- Python 3.8+ (for webhook server)
- Minimum 4GB RAM
- 100MB free disk space

### 🔧 Installation Guide

#### Step 1: Download and Setup

1. Download the AI Expert Advisor files
2. Copy the folder structure to your MetaTrader data directory:
   - For MT4: `MQL4/Experts/AI_Trading_Expert.ex4`
   - For MT5: `MQL5/Experts/AI_Trading_Expert.ex5`
   - Copy all include files to respective directories

#### Step 2: MetaTrader Configuration

1. **Enable AutoTrading**: Click the "AutoTrading" button in MetaTrader
2. **Allow DLL imports**: Tools → Options → Expert Advisors → Check "Allow DLL imports"
3. **Allow WebRequest**: Tools → Options → Expert Advisors → Check "Allow WebRequest"
4. **Add URLs to whitelist**: Add these URLs to the WebRequest whitelist:
   - `https://nfs.faireconomy.media`
   - `https://api.twitter.com`
   - `http://localhost:8080`

#### Step 3: Webhook Server Setup (Optional)

1. Install Python dependencies:
   ```bash
   pip install flask requests
   ```

2. Run the webhook server:
   ```bash
   python webhook_server.py
   ```

3. Configure TradingView alerts to send to: `http://your-ip:8080/webhook`

#### Step 4: Expert Advisor Configuration

1. Drag the EA to your chart
2. Configure the input parameters:

### ⚙️ Configuration Parameters

#### EA Settings
- **InpEAName**: Name of the Expert Advisor
- **InpEnableTrading**: Enable/disable actual trading
- **InpEnableAIAnalysis**: Enable AI-powered analysis
- **InpEnableWebhooks**: Enable webhook signal reception
- **InpEnableSocialSentiment**: Enable social media sentiment analysis

#### Trading Parameters
- **InpLotSize**: Base lot size for trading
- **InpMaxSpread**: Maximum allowed spread (in points)
- **InpMagicNumber**: Unique magic number for trade identification
- **InpSlippage**: Maximum allowed slippage (MT5 only)

#### Visual Settings
- **InpShowDashboard**: Show/hide the visual dashboard
- **InpDashboardColor**: Dashboard background color
- **InpUpdateFrequency**: Update frequency in seconds

#### Risk Management
- **InpMaxRiskPercent**: Maximum risk per trade (% of account)
- **InpMaxPositions**: Maximum number of open positions
- **InpUseTrailingStop**: Enable trailing stop
- **InpTrailingDistance**: Trailing stop distance in points

### 📊 Dashboard Overview

The AI Trading Expert features a comprehensive dashboard displaying:

#### Status Section
- EA status and current mode
- Symbol information
- Current spread
- Account balance and equity

#### AI Analysis Section
- Market sentiment score (-1.0 to 1.0)
- AI recommendation (STRONG BUY, BUY, HOLD, SELL, STRONG SELL)
- Confidence level (0-100%)
- Risk score assessment
- Price target (when available)

#### News & Sentiment Section
- Latest news analysis summary
- Social media sentiment
- Last update timestamp

#### Trade Information
- Number of open positions
- Today's P&L
- Last trade information

#### Control Panel
- Toggle trading on/off
- Refresh AI analysis
- Close all positions
- Access settings

### 🔗 Webhook Integration

#### TradingView Setup

1. Create a TradingView alert
2. Set webhook URL: `http://your-server:8080/webhook`
3. Use this JSON format for the message:

```json
{
    "action": "BUY",
    "symbol": "{{ticker}}",
    "price": "{{close}}",
    "source": "TradingView",
    "lot_size": 0.1,
    "stop_loss": 50,
    "take_profit": 100,
    "comment": "TradingView Signal"
}
```

#### Supported Actions
- `BUY`: Open long position
- `SELL`: Open short position
- `CLOSE`: Close specific position
- `CLOSE_ALL`: Close all positions

#### Custom Signal Providers

You can integrate with any signal provider by sending HTTP POST requests to the webhook endpoint with the appropriate JSON format.

### 🧠 AI Analysis Features

#### News Analysis
- Fetches real-time financial news
- Analyzes sentiment using advanced NLP
- Generates market impact scores
- Provides trading recommendations

#### Social Sentiment Analysis
- Monitors social media platforms
- Tracks market sentiment mentions
- Analyzes influencer opinions
- Generates composite sentiment scores

#### Risk Assessment
- Calculates volatility forecasts
- Assesses market risk levels
- Provides confidence ratings
- Generates position sizing recommendations

### 🛡️ Risk Management

#### Position Sizing
- Fixed lot size mode
- Risk-based position sizing
- Account balance protection
- Maximum position limits

#### Stop Loss & Take Profit
- Automatic SL/TP calculation
- Risk-reward ratio optimization
- Trailing stop functionality
- Market volatility adjustment

#### Drawdown Protection
- Maximum drawdown limits
- Position reduction on losses
- Account equity monitoring
- Emergency stop mechanisms

### 📈 Performance Monitoring

#### Logging System
- Comprehensive trade logging
- AI analysis history
- Error tracking and debugging
- Performance metrics

#### Reporting Features
- Daily/weekly/monthly reports
- Win rate analysis
- Risk-adjusted returns
- AI recommendation accuracy

### 🚨 Troubleshooting

#### Common Issues

**EA not receiving webhooks:**
- Check firewall settings
- Verify webhook server is running
- Confirm URL whitelist settings
- Test webhook endpoint manually

**AI analysis not updating:**
- Check internet connection
- Verify API keys (if required)
- Review log files for errors
- Restart EA if necessary

**Trading not executing:**
- Ensure AutoTrading is enabled
- Check account permissions
- Verify sufficient margin
- Review risk management settings

#### Log Files Location
- MT4: `MQL4/Files/AI_Trading_Expert_[date].log`
- MT5: `MQL5/Files/AI_Trading_Expert_[date].log`
- Webhook: `webhook_server.log`

### 📞 Support & Updates

#### Getting Help
- Review this documentation thoroughly
- Check log files for error messages
- Test with demo account first
- Contact support with specific error details

#### Updates & Maintenance
- Regular updates will be provided
- Backup your settings before updating
- Test new versions on demo accounts
- Subscribe to notifications for updates

### ⚖️ Disclaimer

**IMPORTANT RISK WARNING:**

Trading foreign exchange and CFDs involves significant risk and may result in the loss of your invested capital. You should not invest more than you can afford to lose and should ensure that you fully understand the risks involved. This Expert Advisor is a tool to assist in trading decisions and does not guarantee profits. Past performance is not indicative of future results.

- Use proper risk management
- Test on demo accounts first
- Never risk more than you can afford to lose
- AI analysis is for informational purposes only
- Manual oversight is always recommended

### 📄 License

Copyright 2024, AI Trading Team. All rights reserved.

This software is provided for educational and trading purposes. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the copyright notice and this disclaimer are retained.

---

**Version**: 1.0
**Last Updated**: 2024
**Compatibility**: MT4/MT5
**Support**: Available through official channels