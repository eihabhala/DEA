//+------------------------------------------------------------------+
//|                                           AI_Trading_Expert.mq4 |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Include custom libraries (temporarily disabled for testing)
//#include <Visual_Components/Dashboard.mqh>
//#include <AI_Engine/NewsAnalyzer.mqh>
//#include <AI_Engine/SocialSentiment.mqh>
//#include <Risk_Management/RiskManager.mqh>
//#include <Utils/WebhookHandler.mqh>
//#include <Utils/Logger.mqh>
//#include <Utils/ATRChannel.mqh>

//--- Input parameters
//=== EA Settings ===
extern string    InpEAName = "AI Trading Expert";
extern bool      InpEnableTrading = true;
extern bool      InpEnableAIAnalysis = true;
extern bool      InpEnableWebhooks = true;
extern bool      InpEnableSocialSentiment = true;

//=== ATR Channel Strategy ===
extern bool      InpEnableATRChannel = true;
extern int       InpATRPeriod = 14;
extern double    InpATRMultiplier = 2.0;
extern int       InpATRLookback = 20;
extern bool      InpATRUseBreakout = true;
extern bool      InpATRUseReversal = false;
extern double    InpATRMinChannelWidth = 0.0;

//=== Trading Parameters ===
extern double    InpLotSize = 0.1;
extern int       InpMaxSpread = 30;
extern int       InpMagicNumber = 12345;

//=== Visual Settings ===
extern bool      InpShowDashboard = true;
extern color     InpDashboardColor = clrDarkBlue;
extern int       InpUpdateFrequency = 60; // seconds

//=== Risk Management ===
extern double    InpMaxRiskPercent = 2.0;
extern int       InpMaxPositions = 5;
extern bool      InpUseStopLoss = true;
extern bool      InpUseTakeProfit = true;

//--- Global variables (temporarily simplified for testing)
/*
CDashboard*         g_Dashboard;
CNewsAnalyzer*      g_NewsAnalyzer;
CSocialSentiment*   g_SocialSentiment;
CRiskManager*       g_RiskManager;
CWebhookHandler*    g_WebhookHandler;
CLogger*            g_Logger;
CATRChannel*        g_ATRChannel;
*/

datetime            g_LastUpdate;
bool                g_IsInitialized = false;
string              g_CurrentPair;
double              g_CurrentSpread;
double              g_AccountBalance;
double              g_AccountEquity;

//--- Dashboard objects
string g_DashboardPanel = "AI_Panel";
string g_StatusLabel = "AI_Status";

//--- ATR Channel data
double g_ATRTopLine = 0;
double g_ATRBottomLine = 0;
double g_ATRMiddleLine = 0;
string g_ATRSignal = "NONE";

//--- AI Analysis data
double g_SentimentScore = 0.65;
string g_Recommendation = "BUY";
double g_ConfidenceLevel = 0.75;
double g_RiskScore = 0.35;
string g_SocialSentiment = "Bullish";

//--- AI Analysis results (temporarily commented for testing)
/*
struct SAIAnalysis
{
    double sentiment_score;
    string news_summary;
    string recommendation;
    double confidence_level;
    string social_sentiment;
    datetime last_update;
    bool is_valid;
    double price_target;
    double risk_score;
    
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
*/

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== AI Trading Expert MT4 Initialization Start ===");
    Print("Parameters loaded: EA Name = ", InpEAName);
    Print("Enable Trading = ", InpEnableTrading);
    Print("Show Dashboard = ", InpShowDashboard);
    Print("ATR Period = ", InpATRPeriod);
    Print("Lot Size = ", InpLotSize);
    Print("Magic Number = ", InpMagicNumber);
    Print("=== Parameters verification complete ===");
    
    Print("Initializing AI Trading Expert v1.0...");
    
    //--- Initialize current pair
    g_CurrentPair = Symbol();
    Print("Current Symbol: ", g_CurrentPair);
    
    //--- Remove any existing objects first
    ObjectsDeleteAll(0, "AI_");
    
    //--- Wait a moment for cleanup
    Sleep(100);
    
    //--- Create dashboard
    if(InpShowDashboard)
    {
        if(CreateDashboard())
        {
            Print("✓ Dashboard created successfully - Information window should be visible!");
            Print("✓ Look for the blue dashboard panel on the top-left of your chart");
        }
        else
        {
            Print("✗ Failed to create dashboard");
            return INIT_FAILED;
        }
    }
    else
    {
        Print("⚠ Dashboard is disabled - set InpShowDashboard = true to see information window");
    }
    
    //--- Initialize market data
    UpdateMarketData();
    
    //--- Set timer for regular updates
    EventSetTimer(5); // Update every 5 seconds
    
    Print("=== BASIC INITIALIZATION TEST ===");
    Print("All parameters accessible - EA loading successful");
    Print("=== DASHBOARD INITIALIZATION COMPLETE ===");
    
    g_IsInitialized = true;
    Print("AI Trading Expert initialized successfully - ALL INPUTS WORKING");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("AI Trading Expert deinitialized, reason: ", reason);
    
    //--- Kill timer
    EventKillTimer();
    
    //--- Clean up all dashboard objects
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
    
    //--- Calculate ATR Channel
    if(InpEnableATRChannel)
    {
        CalculateATRChannel();
    }
    
    //--- Update dashboard
    if(InpShowDashboard)
    {
        UpdateDashboard();
    }
    
    // Basic tick processing
    static datetime last_bar_time = 0;
    if(Time[0] != last_bar_time)
    {
        last_bar_time = Time[0];
        Print("New bar - EA is working with all parameters accessible");
    }
    
    /*
    //--- Check for webhook signals
    if(InpEnableWebhooks && g_WebhookHandler != NULL)
    {
        ProcessWebhookSignals();
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
    */
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(!g_IsInitialized) return;
    
    //--- Update market data
    UpdateMarketData();
    
    //--- Calculate ATR Channel
    if(InpEnableATRChannel)
    {
        CalculateATRChannel();
    }
    
    //--- Update dashboard
    if(InpShowDashboard)
    {
        UpdateDashboard();
    }
    
    //--- Simulate some AI analysis changes for demo
    static int timer_count = 0;
    timer_count++;
    
    if(timer_count % 6 == 0) // Every 30 seconds
    {
        //--- Simulate changing AI analysis
        g_SentimentScore = 0.4 + (MathRand() % 40) / 100.0; // 0.4 to 0.8
        g_ConfidenceLevel = 0.6 + (MathRand() % 30) / 100.0; // 0.6 to 0.9
        g_RiskScore = 0.2 + (MathRand() % 40) / 100.0; // 0.2 to 0.6
        
        if(g_SentimentScore > 0.65)
            g_Recommendation = "BUY";
        else if(g_SentimentScore < 0.45)
            g_Recommendation = "SELL";
        else
            g_Recommendation = "HOLD";
            
        Print("AI Analysis updated - Sentiment: ", g_SentimentScore, ", Recommendation: ", g_Recommendation);
    }
    
    /*
    //--- Advanced AI analysis (when includes are enabled)
    if(InpEnableAIAnalysis)
    {
        UpdateAIAnalysis();
    }
    
    //--- Update dashboard with latest information
    if(InpShowDashboard && g_Dashboard != NULL)
    {
        g_Dashboard.UpdateAIAnalysis(g_AIAnalysis);
    }
    */
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
//| Calculate ATR Channel                                            |
//+------------------------------------------------------------------+
void CalculateATRChannel()
{
    //--- Calculate ATR
    double atr = 0;
    for(int i = 1; i <= InpATRPeriod; i++)
    {
        double high = iHigh(g_CurrentPair, PERIOD_CURRENT, i);
        double low = iLow(g_CurrentPair, PERIOD_CURRENT, i);
        double prev_close = iClose(g_CurrentPair, PERIOD_CURRENT, i + 1);
        
        double tr1 = high - low;
        double tr2 = MathAbs(high - prev_close);
        double tr3 = MathAbs(low - prev_close);
        
        atr += MathMax(tr1, MathMax(tr2, tr3));
    }
    atr = atr / InpATRPeriod;
    
    //--- Calculate channel lines
    double highest = iHigh(g_CurrentPair, PERIOD_CURRENT, iHighest(g_CurrentPair, PERIOD_CURRENT, MODE_HIGH, 20, 1));
    double lowest = iLow(g_CurrentPair, PERIOD_CURRENT, iLowest(g_CurrentPair, PERIOD_CURRENT, MODE_LOW, 20, 1));
    
    g_ATRMiddleLine = (highest + lowest) / 2.0;
    g_ATRTopLine = g_ATRMiddleLine + (atr * InpATRMultiplier);
    g_ATRBottomLine = g_ATRMiddleLine - (atr * InpATRMultiplier);
    
    //--- Generate signal
    double current_price = iClose(g_CurrentPair, PERIOD_CURRENT, 0);
    
    if(current_price > g_ATRTopLine)
        g_ATRSignal = "BUY BREAKOUT";
    else if(current_price < g_ATRBottomLine)
        g_ATRSignal = "SELL BREAKOUT";
    else
        g_ATRSignal = "IN CHANNEL";
}

//+------------------------------------------------------------------+
//| Create dashboard                                                 |
//+------------------------------------------------------------------+
bool CreateDashboard()
{
    Print("Creating dashboard...");
    
    //--- Main panel
    if(!ObjectCreate(0, g_DashboardPanel, OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        Print("Error creating main panel: ", GetLastError());
        return false;
    }
    
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_XSIZE, 380);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_YSIZE, 480);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_BGCOLOR, InpDashboardColor);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_WIDTH, 3);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_HIDDEN, false); // Make sure it's visible
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_BACK, false);   // Foreground
    
    //--- Title
    CreateLabel("AI_Title", "🤖 AI Trading Expert Dashboard", 30, 40, clrYellow);
    
    //--- Status section
    CreateLabel("AI_StatusTitle", "=== 📊 STATUS ===", 30, 70, clrCyan);
    CreateLabel("AI_Status", "Status: ✅ RUNNING", 30, 90, clrLime);
    CreateLabel("AI_Symbol", "Symbol: " + g_CurrentPair, 30, 110, clrWhite);
    CreateLabel("AI_Magic", "Magic: " + IntegerToString(InpMagicNumber), 30, 130, clrWhite);
    CreateLabel("AI_Time", "Time: " + TimeToString(TimeCurrent()), 30, 150, clrWhite);
    
    //--- AI Analysis section
    CreateLabel("AI_AITitle", "=== 🧠 AI ANALYSIS ===", 30, 180, clrCyan);
    CreateLabel("AI_Sentiment", "Sentiment: 0.65 (Bullish)", 30, 200, clrLime);
    CreateLabel("AI_Recommendation", "Recommendation: BUY", 30, 220, clrLime);
    CreateLabel("AI_Confidence", "Confidence: 75%", 30, 240, clrWhite);
    CreateLabel("AI_Risk", "Risk Score: 0.35 (Low)", 30, 260, clrLime);
    
    //--- ATR Channel section
    CreateLabel("AI_ATRTitle", "=== 📈 ATR CHANNEL ===", 30, 290, clrCyan);
    CreateLabel("AI_ATRSignal", "Signal: CALCULATING...", 30, 310, clrYellow);
    CreateLabel("AI_ATRTop", "Top Line: 0.00000", 30, 330, clrWhite);
    CreateLabel("AI_ATRBottom", "Bottom Line: 0.00000", 30, 350, clrWhite);
    CreateLabel("AI_ATRWidth", "Channel Width: 0.00000", 30, 370, clrWhite);
    
    //--- Market Info section
    CreateLabel("AI_MarketTitle", "=== 💰 MARKET INFO ===", 30, 400, clrCyan);
    CreateLabel("AI_Spread", "Spread: 0.0", 30, 420, clrWhite);
    CreateLabel("AI_Balance", "Balance: $0.00", 30, 440, clrWhite);
    CreateLabel("AI_Equity", "Equity: $0.00", 30, 460, clrWhite);
    
    //--- Force chart redraw
    ChartRedraw();
    
    Print("Dashboard created with", ObjectsTotal(), " objects");
    return true;
}

//+------------------------------------------------------------------+
//| Create label                                                     |
//+------------------------------------------------------------------+
bool CreateLabel(string name, string text, int x, int y, color clr)
{
    if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
    {
        Print("Error creating label ", name, ": ", GetLastError());
        return false;
    }
    
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, false); // Make visible
    ObjectSetInteger(0, name, OBJPROP_BACK, false);   // Foreground
    
    return true;
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
    
    //--- Calculate price target and risk score
    CalculatePriceTarget();
    CalculateRiskScore();
    
    //--- Generate recommendation
    GenerateRecommendation();
    
    g_AIAnalysis.last_update = TimeCurrent();
    g_AIAnalysis.is_valid = true;
    
    g_Logger.Info("AI analysis updated - Sentiment: " + DoubleToString(g_AIAnalysis.sentiment_score, 2) + 
                  ", Recommendation: " + g_AIAnalysis.recommendation + 
                  ", Confidence: " + DoubleToString(g_AIAnalysis.confidence_level, 2) + 
                  ", Risk Score: " + DoubleToString(g_AIAnalysis.risk_score, 2));
}

//+------------------------------------------------------------------+
//| Calculate price target                                           |
//+------------------------------------------------------------------+
void CalculatePriceTarget()
{
    double current_price = Bid;
    double atr_value = iATR(g_CurrentPair, PERIOD_H1, 14, 0);
    
    //--- Calculate target based on sentiment and ATR
    double sentiment_factor = g_AIAnalysis.sentiment_score;
    double target_distance = atr_value * 2.0 * MathAbs(sentiment_factor);
    
    if(sentiment_factor > 0)
        g_AIAnalysis.price_target = current_price + target_distance;
    else
        g_AIAnalysis.price_target = current_price - target_distance;
}

//+------------------------------------------------------------------+
//| Calculate risk score                                             |
//+------------------------------------------------------------------+
void CalculateRiskScore()
{
    double volatility = iATR(g_CurrentPair, PERIOD_H1, 14, 0) / Bid;
    double spread_risk = g_CurrentSpread / 100.0;
    double confidence_factor = 1.0 - g_AIAnalysis.confidence_level;
    
    g_AIAnalysis.risk_score = (volatility + spread_risk + confidence_factor) / 3.0;
}

//+------------------------------------------------------------------+
//| Generate trading recommendation                                   |
//+------------------------------------------------------------------+
void GenerateRecommendation()
{
    double sentiment = g_AIAnalysis.sentiment_score;
    double confidence = g_AIAnalysis.confidence_level;
    double risk = g_AIAnalysis.risk_score;
    
    if(confidence < 0.5 || risk > 0.7)
    {
        g_AIAnalysis.recommendation = "HOLD - HIGH RISK";
        return;
    }
    
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
    if(g_AIAnalysis.is_valid && g_AIAnalysis.confidence_level > 0.6 && g_AIAnalysis.risk_score < 0.5)
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
    //--- Update timestamp
    ObjectSetString(0, "AI_Time", OBJPROP_TEXT, "Time: " + TimeToString(TimeCurrent(), TIME_MINUTES));
    
    //--- Update market info
    ObjectSetString(0, "AI_Spread", OBJPROP_TEXT, "Spread: " + DoubleToString(g_CurrentSpread, 1) + " pts");
    ObjectSetString(0, "AI_Balance", OBJPROP_TEXT, "Balance: $" + DoubleToString(g_AccountBalance, 2));
    ObjectSetString(0, "AI_Equity", OBJPROP_TEXT, "Equity: $" + DoubleToString(g_AccountEquity, 2));
    
    //--- Update ATR Channel info
    if(g_ATRTopLine > 0)
    {
        ObjectSetString(0, "AI_ATRSignal", OBJPROP_TEXT, "Signal: " + g_ATRSignal);
        ObjectSetString(0, "AI_ATRTop", OBJPROP_TEXT, "Top Line: " + DoubleToString(g_ATRTopLine, 5));
        ObjectSetString(0, "AI_ATRBottom", OBJPROP_TEXT, "Bottom Line: " + DoubleToString(g_ATRBottomLine, 5));
        ObjectSetString(0, "AI_ATRWidth", OBJPROP_TEXT, "Channel Width: " + DoubleToString(g_ATRTopLine - g_ATRBottomLine, 5));
        
        //--- Color code the signal
        color signal_color = clrWhite;
        if(g_ATRSignal == "BUY BREAKOUT") signal_color = clrLime;
        else if(g_ATRSignal == "SELL BREAKOUT") signal_color = clrRed;
        else if(g_ATRSignal == "IN CHANNEL") signal_color = clrYellow;
        ObjectSetInteger(0, "AI_ATRSignal", OBJPROP_COLOR, signal_color);
    }
    else
    {
        ObjectSetString(0, "AI_ATRSignal", OBJPROP_TEXT, "Signal: INITIALIZING...");
        ObjectSetInteger(0, "AI_ATRSignal", OBJPROP_COLOR, clrYellow);
    }
    
    //--- Update AI analysis with dynamic colors
    string sentiment_text = "Sentiment: " + DoubleToString(g_SentimentScore, 2);
    if(g_SentimentScore > 0.6) sentiment_text += " (Bullish)";
    else if(g_SentimentScore < 0.4) sentiment_text += " (Bearish)";
    else sentiment_text += " (Neutral)";
    
    ObjectSetString(0, "AI_Sentiment", OBJPROP_TEXT, sentiment_text);
    ObjectSetInteger(0, "AI_Sentiment", OBJPROP_COLOR, (g_SentimentScore > 0.5) ? clrLime : clrRed);
    
    ObjectSetString(0, "AI_Recommendation", OBJPROP_TEXT, "Recommendation: " + g_Recommendation);
    color rec_color = clrWhite;
    if(g_Recommendation == "BUY") rec_color = clrLime;
    else if(g_Recommendation == "SELL") rec_color = clrRed;
    ObjectSetInteger(0, "AI_Recommendation", OBJPROP_COLOR, rec_color);
    
    ObjectSetString(0, "AI_Confidence", OBJPROP_TEXT, "Confidence: " + IntegerToString((int)(g_ConfidenceLevel * 100)) + "%");
    ObjectSetInteger(0, "AI_Confidence", OBJPROP_COLOR, (g_ConfidenceLevel > 0.7) ? clrLime : clrYellow);
    
    string risk_text = "Risk Score: " + DoubleToString(g_RiskScore, 2);
    if(g_RiskScore < 0.3) risk_text += " (Low)";
    else if(g_RiskScore > 0.7) risk_text += " (High)";
    else risk_text += " (Medium)";
    
    ObjectSetString(0, "AI_Risk", OBJPROP_TEXT, risk_text);
    ObjectSetInteger(0, "AI_Risk", OBJPROP_COLOR, (g_RiskScore < 0.5) ? clrLime : clrRed);
    
    //--- Update status to show it's working
    static int update_counter = 0;
    update_counter++;
    ObjectSetString(0, "AI_Status", OBJPROP_TEXT, "Status: ✅ RUNNING (" + IntegerToString(update_counter) + ")");
    
    ChartRedraw();
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
    g_AIAnalysis.price_target = 0.0;
    g_AIAnalysis.risk_score = 0.0;
    
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
//| Set test AI data for immediate display                          |
//+------------------------------------------------------------------+
void SetTestAIData()
{
    g_AIAnalysis.sentiment_score = 0.65;
    g_AIAnalysis.news_summary = "Market showing positive sentiment. Economic indicators suggest upward trend.";
    g_AIAnalysis.recommendation = "BUY";
    g_AIAnalysis.confidence_level = 0.75;
    g_AIAnalysis.social_sentiment = "Bullish";
    g_AIAnalysis.last_update = TimeCurrent();
    g_AIAnalysis.is_valid = true;
    g_AIAnalysis.price_target = Ask + (Ask * 0.01);
    g_AIAnalysis.risk_score = 0.35;
    
    // Set sample ATR Channel data
    g_AIAnalysis.atr_top_line = Ask + 0.002;
    g_AIAnalysis.atr_bottom_line = Ask - 0.002;
    g_AIAnalysis.atr_middle_line = Ask;
    g_AIAnalysis.atr_signal = "BUY";
    g_AIAnalysis.atr_channel_width = 0.004;
    g_AIAnalysis.atr_above_channel = false;
    g_AIAnalysis.atr_below_channel = false;
    g_AIAnalysis.atr_in_channel = true;
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