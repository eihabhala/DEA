//+------------------------------------------------------------------+
//|                                           AI_Trading_Expert.mq4 |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Include custom libraries
#include <Visual_Components/Dashboard.mqh>
#include <AI_Engine/NewsAnalyzer.mqh>
#include <AI_Engine/SocialSentiment.mqh>
#include <Risk_Management/RiskManager.mqh>
#include <Utils/WebhookHandler.mqh>
#include <Utils/Logger.mqh>
#include <Utils/ATRChannel.mqh>

//--- Input parameters
input string    InpEAName = "AI Trading Expert";
input bool      InpEnableTrading = true;
input bool      InpEnableAIAnalysis = true;
input bool      InpEnableWebhooks = true;
input bool      InpEnableSocialSentiment = true;

input group "=== ATR Channel Strategy ==="
input bool      InpEnableATRChannel = true;
input int       InpATRPeriod = 14;
input double    InpATRMultiplier = 2.0;
input int       InpATRLookback = 20;
input bool      InpATRUseBreakout = true;
input bool      InpATRUseReversal = false;
input double    InpATRMinChannelWidth = 0.0;

input group "=== Trading Parameters ==="
input double    InpLotSize = 0.1;
input int       InpMaxSpread = 30;
input int       InpMagicNumber = 12345;
input bool      InpShowDashboard = true;
input color     InpDashboardColor = clrDarkBlue;
input int       InpUpdateFrequency = 60; // seconds

//--- Global variables
CDashboard*         g_Dashboard;
CNewsAnalyzer*      g_NewsAnalyzer;
CSocialSentiment*   g_SocialSentiment;
CRiskManager*       g_RiskManager;
CWebhookHandler*    g_WebhookHandler;
CLogger*            g_Logger;
CATRChannel*        g_ATRChannel;

datetime            g_LastUpdate;
bool                g_IsInitialized = false;
string              g_CurrentPair;
double              g_CurrentSpread;
double              g_AccountBalance;
double              g_AccountEquity;

//--- AI Analysis results
struct SAIAnalysis
{
    double sentiment_score;
    string news_summary;
    string recommendation;
    double confidence_level;
    string social_sentiment;
    datetime last_update;
    bool is_valid;
    
    // ATR Channel data
    double atr_top_line;
    double atr_bottom_line;
    double atr_middle_line;
    string atr_signal;
    double atr_channel_width;
    bool atr_above_channel;
    bool atr_below_channel;
    bool atr_in_channel;
};

SAIAnalysis g_AIAnalysis;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Initializing AI Trading Expert v1.0...");
    
    //--- Initialize logger first
    g_Logger = new CLogger();
    if(!g_Logger.Initialize("AI_Trading_Expert"))
    {
        Print("ERROR: Failed to initialize logger!");
        return INIT_FAILED;
    }
    
    g_Logger.Info("Starting EA initialization");
    
    //--- Initialize current pair
    g_CurrentPair = Symbol();
    
    //--- Initialize dashboard
    if(InpShowDashboard)
    {
        g_Dashboard = new CDashboard();
        if(!g_Dashboard.Initialize(InpDashboardColor))
        {
            g_Logger.Error("Failed to initialize dashboard");
            return INIT_FAILED;
        }
        g_Logger.Info("Dashboard initialized successfully");
    }
    
    //--- Initialize AI components
    if(InpEnableAIAnalysis)
    {
        g_NewsAnalyzer = new CNewsAnalyzer();
        if(!g_NewsAnalyzer.Initialize())
        {
            g_Logger.Error("Failed to initialize news analyzer");
            return INIT_FAILED;
        }
        g_Logger.Info("News analyzer initialized successfully");
    }
    
    if(InpEnableSocialSentiment)
    {
        g_SocialSentiment = new CSocialSentiment();
        if(!g_SocialSentiment.Initialize())
        {
            g_Logger.Error("Failed to initialize social sentiment analyzer");
            return INIT_FAILED;
        }
        g_Logger.Info("Social sentiment analyzer initialized successfully");
    }
    
    //--- Initialize risk manager
    g_RiskManager = new CRiskManager();
    if(!g_RiskManager.Initialize(InpLotSize, InpMagicNumber))
    {
        g_Logger.Error("Failed to initialize risk manager");
        return INIT_FAILED;
    }
    g_Logger.Info("Risk manager initialized successfully");
    
    //--- Initialize webhook handler
    if(InpEnableWebhooks)
    {
        g_WebhookHandler = new CWebhookHandler();
        if(!g_WebhookHandler.Initialize(8080)) // Default port 8080
        {
            g_Logger.Error("Failed to initialize webhook handler");
            return INIT_FAILED;
        }
        g_Logger.Info("Webhook handler initialized successfully");
    }
    
    //--- Initialize ATR Channel strategy
    if(InpEnableATRChannel)
    {
        g_ATRChannel = new CATRChannel();
        if(!g_ATRChannel.Initialize(g_CurrentPair, PERIOD_CURRENT, InpATRPeriod, InpATRMultiplier))
        {
            g_Logger.Error("Failed to initialize ATR Channel strategy");
            return INIT_FAILED;
        }
        
        g_ATRChannel.SetUseBreakoutStrategy(InpATRUseBreakout);
        g_ATRChannel.SetUseReversalStrategy(InpATRUseReversal);
        g_ATRChannel.SetMinChannelWidth(InpATRMinChannelWidth);
        
        g_Logger.Info("ATR Channel strategy initialized successfully");
    }
    
    //--- Initialize AI analysis structure
    ResetAIAnalysis();
    
    //--- Set timer for regular updates
    EventSetTimer(InpUpdateFrequency);
    
    g_IsInitialized = true;
    g_Logger.Info("AI Trading Expert initialized successfully");
    
    //--- Update dashboard with initialization status
    if(InpShowDashboard && g_Dashboard != NULL)
    {
        g_Dashboard.UpdateStatus("INITIALIZED", clrGreen);
        g_Dashboard.UpdateInfo("EA", InpEAName);
        g_Dashboard.UpdateInfo("Symbol", g_CurrentPair);
        g_Dashboard.UpdateInfo("Magic", IntegerToString(InpMagicNumber));
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    g_Logger.Info("Deinitializing AI Trading Expert, reason: " + IntegerToString(reason));
    
    //--- Kill timer
    EventKillTimer();
    
    //--- Clean up objects
    if(g_Dashboard != NULL)
    {
        delete g_Dashboard;
        g_Dashboard = NULL;
    }
    
    if(g_NewsAnalyzer != NULL)
    {
        delete g_NewsAnalyzer;
        g_NewsAnalyzer = NULL;
    }
    
    if(g_SocialSentiment != NULL)
    {
        delete g_SocialSentiment;
        g_SocialSentiment = NULL;
    }
    
    if(g_RiskManager != NULL)
    {
        delete g_RiskManager;
        g_RiskManager = NULL;
    }
    
    if(g_WebhookHandler != NULL)
    {
        delete g_WebhookHandler;
        g_WebhookHandler = NULL;
    }
    
    if(g_ATRChannel != NULL)
    {
        delete g_ATRChannel;
        g_ATRChannel = NULL;
    }
    
    if(g_Logger != NULL)
    {
        g_Logger.Info("AI Trading Expert deinitialized");
        delete g_Logger;
        g_Logger = NULL;
    }
    
    //--- Remove all objects from chart
    ObjectsDeleteAll(0, "AI_");
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!g_IsInitialized) return;
    
    //--- Update basic market data
    UpdateMarketData();
    
    //--- Check for webhook signals
    if(InpEnableWebhooks && g_WebhookHandler != NULL)
    {
        ProcessWebhookSignals();
    }
    
    //--- Update dashboard
    if(InpShowDashboard && g_Dashboard != NULL)
    {
        UpdateDashboard();
    }
    
    //--- Process trading logic
    if(InpEnableTrading)
    {
        ProcessTradingLogic();
    }
    
    //--- Process ATR Channel strategy
    if(InpEnableATRChannel && g_ATRChannel != NULL)
    {
        ProcessATRChannelStrategy();
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(!g_IsInitialized) return;
    
    g_Logger.Debug("Timer event triggered");
    
    //--- Update AI analysis
    if(InpEnableAIAnalysis)
    {
        UpdateAIAnalysis();
    }
    
    //--- Update dashboard with latest information
    if(InpShowDashboard && g_Dashboard != NULL)
    {
        g_Dashboard.UpdateAIAnalysis(g_AIAnalysis);
    }
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if(!g_IsInitialized) return;
    
    //--- Handle dashboard events
    if(InpShowDashboard && g_Dashboard != NULL)
    {
        g_Dashboard.OnChartEvent(id, lparam, dparam, sparam);
    }
}

//+------------------------------------------------------------------+
//| Update market data                                               |
//+------------------------------------------------------------------+
void UpdateMarketData()
{
    g_CurrentSpread = MarketInfo(g_CurrentPair, MODE_SPREAD);
    g_AccountBalance = AccountBalance();
    g_AccountEquity = AccountEquity();
}

//+------------------------------------------------------------------+
//| Process webhook signals                                          |
//+------------------------------------------------------------------+
void ProcessWebhookSignals()
{
    if(g_WebhookHandler == NULL) return;
    
    string signals[];
    int count = g_WebhookHandler.GetNewSignals(signals);
    
    for(int i = 0; i < count; i++)
    {
        g_Logger.Info("Processing webhook signal: " + signals[i]);
        ParseAndExecuteSignal(signals[i]);
    }
}

//+------------------------------------------------------------------+
//| Parse and execute trading signal                                 |
//+------------------------------------------------------------------+
void ParseAndExecuteSignal(string signal)
{
    //--- Parse JSON signal (basic implementation)
    if(StringFind(signal, "BUY") >= 0)
    {
        g_Logger.Info("Buy signal received from webhook");
        if(g_RiskManager.CanOpenTrade(OP_BUY))
        {
            ExecuteTrade(OP_BUY, "Webhook Signal");
        }
    }
    else if(StringFind(signal, "SELL") >= 0)
    {
        g_Logger.Info("Sell signal received from webhook");
        if(g_RiskManager.CanOpenTrade(OP_SELL))
        {
            ExecuteTrade(OP_SELL, "Webhook Signal");
        }
    }
    else if(StringFind(signal, "CLOSE") >= 0)
    {
        g_Logger.Info("Close signal received from webhook");
        g_RiskManager.CloseAllTrades();
    }
}

//+------------------------------------------------------------------+
//| Update AI analysis                                               |
//+------------------------------------------------------------------+
void UpdateAIAnalysis()
{
    g_Logger.Debug("Updating AI analysis");
    
    //--- Reset analysis
    ResetAIAnalysis();
    
    //--- Get news analysis
    if(g_NewsAnalyzer != NULL)
    {
        SNewsAnalysis news_result = g_NewsAnalyzer.AnalyzeLatestNews(g_CurrentPair);
        g_AIAnalysis.sentiment_score = news_result.sentiment_score;
        g_AIAnalysis.news_summary = news_result.summary;
        g_AIAnalysis.confidence_level = news_result.confidence;
    }
    
    //--- Get social sentiment
    if(g_SocialSentiment != NULL)
    {
        SSocialSentiment social_result = g_SocialSentiment.GetSentiment(g_CurrentPair);
        g_AIAnalysis.social_sentiment = social_result.sentiment;
    }
    
    //--- Generate recommendation
    GenerateRecommendation();
    
    g_AIAnalysis.last_update = TimeCurrent();
    g_AIAnalysis.is_valid = true;
    
    g_Logger.Info("AI analysis updated - Sentiment: " + DoubleToString(g_AIAnalysis.sentiment_score, 2) + 
                  ", Recommendation: " + g_AIAnalysis.recommendation);
}

//+------------------------------------------------------------------+
//| Generate trading recommendation                                   |
//+------------------------------------------------------------------+
void GenerateRecommendation()
{
    double sentiment = g_AIAnalysis.sentiment_score;
    
    if(sentiment > 0.7)
    {
        g_AIAnalysis.recommendation = "STRONG BUY";
    }
    else if(sentiment > 0.3)
    {
        g_AIAnalysis.recommendation = "BUY";
    }
    else if(sentiment > -0.3)
    {
        g_AIAnalysis.recommendation = "HOLD";
    }
    else if(sentiment > -0.7)
    {
        g_AIAnalysis.recommendation = "SELL";
    }
    else
    {
        g_AIAnalysis.recommendation = "STRONG SELL";
    }
}

//+------------------------------------------------------------------+
//| Process trading logic                                            |
//+------------------------------------------------------------------+
void ProcessTradingLogic()
{
    if(!InpEnableTrading) return;
    
    //--- Check spread
    if(g_CurrentSpread > InpMaxSpread)
    {
        return;
    }
    
    //--- Use AI analysis for trading decisions
    if(g_AIAnalysis.is_valid && g_AIAnalysis.confidence_level > 0.6)
    {
        if(g_AIAnalysis.recommendation == "STRONG BUY" && g_RiskManager.CanOpenTrade(OP_BUY))
        {
            ExecuteTrade(OP_BUY, "AI Strong Buy Signal");
        }
        else if(g_AIAnalysis.recommendation == "STRONG SELL" && g_RiskManager.CanOpenTrade(OP_SELL))
        {
            ExecuteTrade(OP_SELL, "AI Strong Sell Signal");
        }
    }
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(int operation, string comment)
{
    if(g_RiskManager == NULL) return;
    
    double lot_size = g_RiskManager.CalculateLotSize();
    double price = (operation == OP_BUY) ? Ask : Bid;
    double sl = g_RiskManager.CalculateStopLoss(operation, price);
    double tp = g_RiskManager.CalculateTakeProfit(operation, price);
    
    int ticket = OrderSend(g_CurrentPair, operation, lot_size, price, 3, sl, tp, comment, InpMagicNumber, 0, clrNONE);
    
    if(ticket > 0)
    {
        g_Logger.Info("Trade executed successfully - Ticket: " + IntegerToString(ticket) + 
                      ", Type: " + ((operation == OP_BUY) ? "BUY" : "SELL") + 
                      ", Size: " + DoubleToString(lot_size, 2));
    }
    else
    {
        g_Logger.Error("Failed to execute trade - Error: " + IntegerToString(GetLastError()));
    }
}

//+------------------------------------------------------------------+
//| Update dashboard                                                 |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    if(g_Dashboard == NULL) return;
    
    //--- Update market information
    g_Dashboard.UpdateInfo("Spread", DoubleToString(g_CurrentSpread, 1));
    g_Dashboard.UpdateInfo("Balance", DoubleToString(g_AccountBalance, 2));
    g_Dashboard.UpdateInfo("Equity", DoubleToString(g_AccountEquity, 2));
    
    //--- Update trading status
    if(InpEnableTrading)
    {
        g_Dashboard.UpdateStatus("TRADING", clrGreen);
    }
    else
    {
        g_Dashboard.UpdateStatus("MONITORING", clrOrange);
    }
}

//+------------------------------------------------------------------+
//| Reset AI analysis structure                                      |
//+------------------------------------------------------------------+
void ResetAIAnalysis()
{
    g_AIAnalysis.sentiment_score = 0.0;
    g_AIAnalysis.news_summary = "";
    g_AIAnalysis.recommendation = "ANALYZING...";
    g_AIAnalysis.confidence_level = 0.0;
    g_AIAnalysis.social_sentiment = "";
    g_AIAnalysis.last_update = 0;
    g_AIAnalysis.is_valid = false;
    
    // Reset ATR Channel data
    g_AIAnalysis.atr_top_line = 0.0;
    g_AIAnalysis.atr_bottom_line = 0.0;
    g_AIAnalysis.atr_middle_line = 0.0;
    g_AIAnalysis.atr_signal = "NONE";
    g_AIAnalysis.atr_channel_width = 0.0;
    g_AIAnalysis.atr_above_channel = false;
    g_AIAnalysis.atr_below_channel = false;
    g_AIAnalysis.atr_in_channel = false;
}

//+------------------------------------------------------------------+
//| Process ATR Channel Strategy                                     |
//+------------------------------------------------------------------+
void ProcessATRChannelStrategy()
{
    if(g_ATRChannel == NULL || !InpEnableTrading) return;
    
    //--- Update ATR Channel calculations
    if(!g_ATRChannel.CalculateATRChannel(0))
    {
        g_Logger.Warning("Failed to calculate ATR Channel");
        return;
    }
    
    //--- Get channel data
    SATRChannelData channel_data = g_ATRChannel.GetChannelData(0);
    if(!channel_data.is_valid) return;
    
    //--- Update AI analysis with ATR data
    g_AIAnalysis.atr_top_line = channel_data.top_line;
    g_AIAnalysis.atr_bottom_line = channel_data.bottom_line;
    g_AIAnalysis.atr_middle_line = channel_data.middle_line;
    g_AIAnalysis.atr_channel_width = channel_data.channel_width;
    g_AIAnalysis.atr_above_channel = g_ATRChannel.IsPriceAboveChannel();
    g_AIAnalysis.atr_below_channel = g_ATRChannel.IsPriceBelowChannel();
    g_AIAnalysis.atr_in_channel = g_ATRChannel.IsPriceInChannel();
    
    //--- Convert signal to string
    switch(channel_data.signal)
    {
        case ATR_SIGNAL_BUY:
            g_AIAnalysis.atr_signal = "BUY";
            break;
        case ATR_SIGNAL_SELL:
            g_AIAnalysis.atr_signal = "SELL";
            break;
        default:
            g_AIAnalysis.atr_signal = "NONE";
            break;
    }
    
    //--- Check spread
    if(g_CurrentSpread > InpMaxSpread)
    {
        return;
    }
    
    //--- Execute ATR Channel signals
    if(channel_data.signal == ATR_SIGNAL_BUY && g_RiskManager.CanOpenTrade(OP_BUY))
    {
        string comment = "ATR Channel Buy - " + DoubleToString(channel_data.top_line, 5);
        ExecuteTrade(OP_BUY, comment);
        g_Logger.Info("ATR Channel BUY signal executed - Channel Width: " + DoubleToString(channel_data.channel_width, 5));
    }
    else if(channel_data.signal == ATR_SIGNAL_SELL && g_RiskManager.CanOpenTrade(OP_SELL))
    {
        string comment = "ATR Channel Sell - " + DoubleToString(channel_data.bottom_line, 5);
        ExecuteTrade(OP_SELL, comment);
        g_Logger.Info("ATR Channel SELL signal executed - Channel Width: " + DoubleToString(channel_data.channel_width, 5));
    }
}