//+------------------------------------------------------------------+
//|                                              EA_Configuration.mqh |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

// ============================================================================
// AI TRADING EXPERT ADVISOR - CONFIGURATION TEMPLATE
// ============================================================================
// Copy this file and modify the settings according to your preferences
// Save as "Config/MySettings.mqh" and include in your EA

#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"

// ============================================================================
// TRADING CONFIGURATION
// ============================================================================

// Basic Trading Settings
input string    CONFIG_EA_NAME = "AI Trading Expert - Custom Config";
input bool      CONFIG_ENABLE_TRADING = true;         // Enable live trading
input bool      CONFIG_ENABLE_AI_ANALYSIS = true;     // Enable AI analysis
input bool      CONFIG_ENABLE_WEBHOOKS = true;        // Enable webhook signals
input bool      CONFIG_ENABLE_SOCIAL_SENTIMENT = true; // Enable social sentiment

// Position Sizing
input double    CONFIG_LOT_SIZE = 0.1;                // Base lot size
input bool      CONFIG_USE_RISK_BASED_SIZING = true;  // Use risk-based position sizing
input double    CONFIG_RISK_PERCENT = 2.0;            // Risk percentage per trade
input double    CONFIG_MAX_LOT_SIZE = 1.0;            // Maximum lot size
input double    CONFIG_MIN_LOT_SIZE = 0.01;           // Minimum lot size

// Risk Management
input int       CONFIG_MAX_POSITIONS = 5;             // Maximum open positions
input int       CONFIG_STOP_LOSS_PIPS = 50;          // Stop loss in pips
input int       CONFIG_TAKE_PROFIT_PIPS = 100;       // Take profit in pips
input double    CONFIG_MAX_DRAWDOWN_PERCENT = 20.0;   // Maximum drawdown %
input bool      CONFIG_USE_TRAILING_STOP = true;     // Enable trailing stop
input int       CONFIG_TRAILING_DISTANCE = 30;       // Trailing stop distance

// Market Conditions
input int       CONFIG_MAX_SPREAD = 30;               // Maximum spread allowed
input int       CONFIG_SLIPPAGE = 10;                 // Maximum slippage (MT5)
input ulong     CONFIG_MAGIC_NUMBER = 12345;          // Magic number

// ============================================================================
// AI ANALYSIS CONFIGURATION
// ============================================================================

// News Analysis Settings
input bool      CONFIG_NEWS_ENABLE = true;           // Enable news analysis
input int       CONFIG_NEWS_UPDATE_MINUTES = 60;     // News update frequency
input int       CONFIG_NEWS_ANALYSIS_HOURS = 24;     // Analysis timeframe
input double    CONFIG_NEWS_MIN_CONFIDENCE = 0.6;    // Minimum confidence for trading
input string    CONFIG_NEWS_API_KEY = "";            // News API key (optional)

// Social Sentiment Settings
input bool      CONFIG_SOCIAL_ENABLE = true;         // Enable social sentiment
input int       CONFIG_SOCIAL_UPDATE_MINUTES = 30;   // Social update frequency
input double    CONFIG_SOCIAL_MIN_CONFIDENCE = 0.5;  // Minimum social confidence
input string    CONFIG_SOCIAL_API_KEY = "";          // Social API key (optional)

// AI Trading Thresholds
input double    CONFIG_AI_BUY_THRESHOLD = 0.3;       // AI buy signal threshold
input double    CONFIG_AI_SELL_THRESHOLD = -0.3;     // AI sell signal threshold
input double    CONFIG_AI_STRONG_BUY_THRESHOLD = 0.7; // Strong buy threshold
input double    CONFIG_AI_STRONG_SELL_THRESHOLD = -0.7; // Strong sell threshold

// ============================================================================
// VISUAL DASHBOARD CONFIGURATION
// ============================================================================

// Dashboard Settings
input bool      CONFIG_SHOW_DASHBOARD = true;        // Show visual dashboard
input color     CONFIG_DASHBOARD_COLOR = clrDarkBlue; // Dashboard background color
input int       CONFIG_DASHBOARD_UPDATE_SECONDS = 5; // Dashboard update frequency
input bool      CONFIG_DASHBOARD_SHOW_NEWS = true;   // Show news panel
input bool      CONFIG_DASHBOARD_SHOW_SOCIAL = true; // Show social panel

// Dashboard Position and Size
input int       CONFIG_DASHBOARD_X = 20;             // Dashboard X position
input int       CONFIG_DASHBOARD_Y = 30;             // Dashboard Y position
input int       CONFIG_DASHBOARD_WIDTH = 400;        // Dashboard width
input int       CONFIG_DASHBOARD_HEIGHT = 600;       // Dashboard height

// ============================================================================
// WEBHOOK CONFIGURATION
// ============================================================================

// Webhook Server Settings
input string    CONFIG_WEBHOOK_SERVER = "localhost"; // Webhook server address
input int       CONFIG_WEBHOOK_PORT = 8080;          // Webhook server port
input bool      CONFIG_WEBHOOK_USE_AUTH = false;     // Use authentication
input string    CONFIG_WEBHOOK_AUTH_TOKEN = "";      // Authentication token
input bool      CONFIG_WEBHOOK_VALIDATE_SOURCE = true; // Validate signal source

// Signal Processing
input bool      CONFIG_WEBHOOK_AUTO_EXECUTE = true;  // Auto-execute webhook signals
input double    CONFIG_WEBHOOK_MAX_LOT = 0.5;        // Max lot size for webhooks
input bool      CONFIG_WEBHOOK_RESPECT_RISK = true;  // Apply risk management to webhooks
input bool      CONFIG_WEBHOOK_LOG_SIGNALS = true;   // Log all webhook signals

// ============================================================================
// LOGGING CONFIGURATION
// ============================================================================

// Log Settings
input bool      CONFIG_LOG_ENABLE = true;            // Enable logging
input int       CONFIG_LOG_LEVEL = 1;                // Log level (0=Debug, 1=Info, 2=Warning, 3=Error)
input bool      CONFIG_LOG_TO_FILE = true;           // Write logs to file
input bool      CONFIG_LOG_TO_TERMINAL = true;       // Write logs to terminal
input bool      CONFIG_LOG_TRADES = true;            // Log all trades
input bool      CONFIG_LOG_AI_ANALYSIS = true;       // Log AI analysis results

// File Management
input int       CONFIG_LOG_MAX_FILE_SIZE_MB = 10;    // Maximum log file size
input int       CONFIG_LOG_KEEP_DAYS = 30;           // Keep log files for X days
input bool      CONFIG_LOG_COMPRESS_OLD = false;     // Compress old log files

// ============================================================================
// ADVANCED CONFIGURATION
// ============================================================================

// Performance Settings
input int       CONFIG_TIMER_INTERVAL_SECONDS = 60;  // Main timer interval
input bool      CONFIG_OPTIMIZE_PERFORMANCE = true;  // Enable performance optimizations
input int       CONFIG_MAX_HISTORY_BARS = 1000;     // Maximum history bars to analyze
input bool      CONFIG_CACHE_AI_RESULTS = true;      // Cache AI analysis results

// Development and Testing
input bool      CONFIG_DEMO_MODE = false;            // Enable demo mode (uses fake data)
input bool      CONFIG_BACKTEST_MODE = false;        // Special backtest optimizations
input bool      CONFIG_DEBUG_MODE = false;           // Enable debug output
input bool      CONFIG_VERBOSE_LOGGING = false;      // Extra verbose logging

// API Rate Limiting
input int       CONFIG_API_CALLS_PER_HOUR = 1000;    // Maximum API calls per hour
input int       CONFIG_API_RETRY_ATTEMPTS = 3;       // API retry attempts
input int       CONFIG_API_TIMEOUT_SECONDS = 30;     // API timeout

// ============================================================================
// SYMBOL-SPECIFIC SETTINGS
// ============================================================================

// Major Pairs Configuration
struct SSymbolConfig
{
    string symbol;
    double lot_multiplier;
    int stop_loss_pips;
    int take_profit_pips;
    double risk_multiplier;
    bool enable_trading;
};

// Predefined symbol configurations
SSymbolConfig CONFIG_SYMBOL_SETTINGS[] = {
    {"EURUSD", 1.0, 50, 100, 1.0, true},
    {"GBPUSD", 1.0, 60, 120, 1.2, true},
    {"USDJPY", 0.8, 40, 80, 0.8, true},
    {"AUDUSD", 1.0, 55, 110, 1.1, true},
    {"USDCAD", 1.0, 50, 100, 1.0, true},
    {"USDCHF", 0.9, 45, 90, 0.9, true},
    {"NZDUSD", 1.0, 60, 120, 1.3, true},
    {"EURGBP", 1.0, 40, 80, 0.9, true}
};

// ============================================================================
// TIME-BASED TRADING FILTERS
// ============================================================================

// Trading Hours (GMT)
input bool      CONFIG_USE_TRADING_HOURS = true;     // Enable trading hours filter
input int       CONFIG_TRADING_START_HOUR = 6;       // Trading start hour (GMT)
input int       CONFIG_TRADING_END_HOUR = 22;        // Trading end hour (GMT)
input bool      CONFIG_TRADE_SUNDAY = false;         // Trade on Sunday
input bool      CONFIG_TRADE_FRIDAY_EVENING = false; // Trade Friday evening

// News Blackout Periods
input bool      CONFIG_USE_NEWS_FILTER = true;       // Avoid trading during news
input int       CONFIG_NEWS_BLACKOUT_MINUTES = 30;   // Minutes before/after news
input bool      CONFIG_CLOSE_BEFORE_NEWS = true;     // Close positions before high-impact news

// ============================================================================
// ALERT CONFIGURATION
// ============================================================================

// Alert Settings
input bool      CONFIG_SEND_ALERTS = true;           // Send alerts
input bool      CONFIG_ALERT_ON_TRADE_OPEN = true;   // Alert when trade opens
input bool      CONFIG_ALERT_ON_TRADE_CLOSE = true;  // Alert when trade closes
input bool      CONFIG_ALERT_ON_AI_SIGNAL = false;   // Alert on AI signals
input bool      CONFIG_ALERT_ON_ERROR = true;        // Alert on errors

// Notification Methods
input bool      CONFIG_ALERT_POPUP = true;           // Show popup alerts
input bool      CONFIG_ALERT_EMAIL = false;          // Send email alerts
input bool      CONFIG_ALERT_PUSH = false;           // Send push notifications
input bool      CONFIG_ALERT_SOUND = true;           // Play sound alerts

// ============================================================================
// NOTES FOR CUSTOMIZATION
// ============================================================================

/*
CUSTOMIZATION GUIDE:

1. BASIC SETUP:
   - Set CONFIG_ENABLE_TRADING to false for testing
   - Adjust CONFIG_LOT_SIZE and CONFIG_RISK_PERCENT for your account size
   - Set CONFIG_MAGIC_NUMBER to unique value if running multiple EAs

2. RISK MANAGEMENT:
   - CONFIG_MAX_DRAWDOWN_PERCENT: Never risk more than you can afford
   - CONFIG_MAX_POSITIONS: Limit concurrent trades
   - CONFIG_STOP_LOSS_PIPS: Always use stop losses

3. AI CONFIGURATION:
   - Higher CONFIG_AI_*_THRESHOLD values = more conservative trading
   - CONFIG_NEWS_MIN_CONFIDENCE: Increase for higher quality signals
   - Set API keys for enhanced news and social analysis

4. DASHBOARD:
   - Set CONFIG_SHOW_DASHBOARD to false to hide visual interface
   - Adjust position and colors to match your preferences

5. WEBHOOKS:
   - Configure server details to match your webhook setup
   - Enable authentication for security in live environment

6. TESTING:
   - Use CONFIG_DEMO_MODE for initial testing
   - Enable CONFIG_DEBUG_MODE for troubleshooting
   - Check logs regularly during initial setup

REMEMBER:
- Always test on demo account first
- Start with conservative settings
- Monitor performance and adjust gradually
- Keep regular backups of your configuration
*/