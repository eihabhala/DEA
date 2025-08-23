//+------------------------------------------------------------------+
//|                                     AI_Trading_Expert_Test.mq4 |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Input parameters - BASIC TEST VERSION
extern string    InpEAName = "AI Trading Expert";
extern bool      InpEnableTrading = true;
extern bool      InpEnableAIAnalysis = true;
extern bool      InpEnableWebhooks = true;
extern bool      InpEnableSocialSentiment = true;

extern bool      InpEnableATRChannel = true;
extern int       InpATRPeriod = 14;
extern double    InpATRMultiplier = 2.0;
extern int       InpATRLookback = 20;
extern bool      InpATRUseBreakout = true;
extern bool      InpATRUseReversal = false;
extern double    InpATRMinChannelWidth = 0.0;

extern double    InpLotSize = 0.1;
extern int       InpMaxSpread = 30;
extern int       InpMagicNumber = 12345;

extern bool      InpShowDashboard = true;
extern color     InpDashboardColor = clrDarkBlue;
extern int       InpUpdateFrequency = 60;

extern double    InpMaxRiskPercent = 2.0;
extern int       InpMaxPositions = 5;
extern bool      InpUseStopLoss = true;
extern bool      InpUseTakeProfit = true;

//--- Global variables
bool g_IsInitialized = false;
string g_CurrentPair;
double g_CurrentSpread;
double g_AccountBalance;
double g_AccountEquity;

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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== AI Trading Expert Test Version ===");
    Print("EA Name: ", InpEAName);
    Print("Enable Trading: ", InpEnableTrading);
    Print("Enable AI Analysis: ", InpEnableAIAnalysis);
    Print("Enable Webhooks: ", InpEnableWebhooks);
    Print("Enable Social Sentiment: ", InpEnableSocialSentiment);
    Print("Enable ATR Channel: ", InpEnableATRChannel);
    Print("ATR Period: ", InpATRPeriod);
    Print("ATR Multiplier: ", InpATRMultiplier);
    Print("ATR Lookback: ", InpATRLookback);
    Print("ATR Use Breakout: ", InpATRUseBreakout);
    Print("ATR Use Reversal: ", InpATRUseReversal);
    Print("ATR Min Channel Width: ", InpATRMinChannelWidth);
    Print("Lot Size: ", InpLotSize);
    Print("Max Spread: ", InpMaxSpread);
    Print("Magic Number: ", InpMagicNumber);
    Print("Show Dashboard: ", InpShowDashboard);
    Print("Dashboard Color: ", InpDashboardColor);
    Print("Update Frequency: ", InpUpdateFrequency);
    Print("Max Risk Percent: ", InpMaxRiskPercent);
    Print("Max Positions: ", InpMaxPositions);
    Print("Use Stop Loss: ", InpUseStopLoss);
    Print("Use Take Profit: ", InpUseTakeProfit);
    
    g_CurrentPair = Symbol();
    
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
    
    //--- Set up timer for regular updates
    EventSetTimer(5); // Update every 5 seconds
    
    Print("=== ALL INPUT PARAMETERS LOADED SUCCESSFULLY ===");
    Print("=== DASHBOARD INITIALIZATION COMPLETE ===");
    
    g_IsInitialized = true;
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("AI Trading Expert Test deinitialized, reason: ", reason);
    
    //--- Kill timer
    EventKillTimer();
    
    //--- Clean up all dashboard objects
    ObjectsDeleteAll(0, "AI_");
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Timer function for regular updates                               |
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
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
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
    
    // Basic tick processing
    static datetime last_bar_time = 0;
    if(Time[0] != last_bar_time)
    {
        last_bar_time = Time[0];
        Print("New bar - EA is working with all parameters accessible");
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