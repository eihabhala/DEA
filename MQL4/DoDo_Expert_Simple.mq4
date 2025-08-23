//+------------------------------------------------------------------+
//|                                              DoDo_Expert_Simple.mq4 |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Input parameters
input group "=== EA Settings ==="
input string    InpEAName = "DoDo Expert Advisor - Simple";
input bool      InpEnableTrading = false;         // Enable live trading (start with false for testing)
input bool      InpShowDashboard = true;          // Show visual dashboard
input int       InpMagicNumber = 12345;           // Magic number

input group "=== ATR Channel Strategy ==="
input bool      InpEnableATRChannel = true;       // Enable ATR Channel strategy
input int       InpATRPeriod = 14;                // ATR calculation period
input double    InpATRMultiplier = 2.0;           // ATR multiplier for channel width
input bool      InpATRUseBreakout = true;         // Enable breakout signals

input group "=== Trading Parameters ==="
input double    InpLotSize = 0.1;                 // Base lot size
input int       InpMaxSpread = 30;                // Maximum spread allowed
input int       InpStopLoss = 50;                 // Stop loss in pips
input int       InpTakeProfit = 100;              // Take profit in pips

input group "=== Visual Settings ==="
input color     InpDashboardColor = clrDarkBlue;  // Dashboard background color
input int       InpUpdateFrequency = 60;          // Update frequency in seconds

//--- Global variables
datetime        g_LastUpdate;
bool            g_IsInitialized = false;
string          g_CurrentPair;
double          g_CurrentSpread;

//--- ATR Channel data
double          g_ATRTopLine = 0;
double          g_ATRBottomLine = 0;
double          g_ATRMiddleLine = 0;
string          g_ATRSignal = "NONE";

//--- Dashboard objects
string          g_DashboardPanel = "DoDo_Panel";
string          g_StatusLabel = "DoDo_Status";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Initializing DoDo Expert Advisor - Simple Version");
    
    //--- Initialize current pair
    g_CurrentPair = Symbol();
    
    //--- Create dashboard
    if(InpShowDashboard)
    {
        CreateDashboard();
    }
    
    //--- Set timer for regular updates
    EventSetTimer(InpUpdateFrequency);
    
    g_IsInitialized = true;
    
    Print("DoDo Expert Advisor initialized successfully");
    Print("EA Name: ", InpEAName);
    Print("Symbol: ", g_CurrentPair);
    Print("Magic Number: ", InpMagicNumber);
    Print("Trading Enabled: ", InpEnableTrading ? "YES" : "NO");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Deinitializing DoDo Expert Advisor, reason: ", reason);
    
    //--- Kill timer
    EventKillTimer();
    
    //--- Remove dashboard objects
    ObjectsDeleteAll(0, "DoDo_");
    ChartRedraw();
    
    Print("DoDo Expert Advisor deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!g_IsInitialized) return;
    
    //--- Update market data
    UpdateMarketData();
    
    //--- Calculate ATR Channel if enabled
    if(InpEnableATRChannel)
    {
        CalculateATRChannel();
    }
    
    //--- Update dashboard
    if(InpShowDashboard)
    {
        UpdateDashboard();
    }
    
    //--- Trading logic (only if enabled)
    if(InpEnableTrading)
    {
        ProcessTradingLogic();
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(!g_IsInitialized) return;
    
    Print("Timer update - Current time: ", TimeToString(TimeCurrent()));
    
    //--- Force dashboard update
    if(InpShowDashboard)
    {
        UpdateDashboard();
    }
}

//+------------------------------------------------------------------+
//| Update market data                                               |
//+------------------------------------------------------------------+
void UpdateMarketData()
{
    g_CurrentSpread = MarketInfo(g_CurrentPair, MODE_SPREAD);
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
//| Process trading logic                                            |
//+------------------------------------------------------------------+
void ProcessTradingLogic()
{
    //--- Check spread
    if(g_CurrentSpread > InpMaxSpread) return;
    
    //--- Simple ATR breakout strategy
    if(InpATRUseBreakout && g_ATRSignal == "BUY BREAKOUT")
    {
        //--- Check if we can open buy trade
        if(CanOpenTrade())
        {
            ExecuteTrade(OP_BUY, "DoDo ATR Buy Breakout");
        }
    }
    else if(InpATRUseBreakout && g_ATRSignal == "SELL BREAKOUT")
    {
        //--- Check if we can open sell trade
        if(CanOpenTrade())
        {
            ExecuteTrade(OP_SELL, "DoDo ATR Sell Breakout");
        }
    }
}

//+------------------------------------------------------------------+
//| Check if can open trade                                         |
//+------------------------------------------------------------------+
bool CanOpenTrade()
{
    //--- Count open positions with our magic number
    int open_positions = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == InpMagicNumber && OrderSymbol() == g_CurrentPair)
                open_positions++;
        }
    }
    
    //--- Allow only 1 position at a time for simplicity
    return (open_positions == 0);
}

//+------------------------------------------------------------------+
//| Execute trade                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade(int operation, string comment)
{
    double price = (operation == OP_BUY) ? Ask : Bid;
    double sl = 0, tp = 0;
    
    //--- Calculate stop loss and take profit
    if(InpStopLoss > 0)
    {
        if(operation == OP_BUY)
            sl = price - (InpStopLoss * Point);
        else
            sl = price + (InpStopLoss * Point);
    }
    
    if(InpTakeProfit > 0)
    {
        if(operation == OP_BUY)
            tp = price + (InpTakeProfit * Point);
        else
            tp = price - (InpTakeProfit * Point);
    }
    
    //--- Open order
    int ticket = OrderSend(g_CurrentPair, operation, InpLotSize, price, 3, sl, tp, comment, InpMagicNumber, 0, clrNONE);
    
    if(ticket > 0)
    {
        Print("Trade executed successfully - Ticket: ", ticket, ", Type: ", (operation == OP_BUY ? "BUY" : "SELL"));
    }
    else
    {
        Print("Failed to execute trade - Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Create dashboard                                                |
//+------------------------------------------------------------------+
void CreateDashboard()
{
    //--- Main panel
    ObjectCreate(0, g_DashboardPanel, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_XSIZE, 300);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_YSIZE, 200);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_BGCOLOR, InpDashboardColor);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, g_DashboardPanel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    
    //--- Status label
    ObjectCreate(0, g_StatusLabel, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, g_StatusLabel, OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, g_StatusLabel, OBJPROP_YDISTANCE, 40);
    ObjectSetString(0, g_StatusLabel, OBJPROP_TEXT, "DoDo Expert Advisor - INITIALIZING");
    ObjectSetInteger(0, g_StatusLabel, OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, g_StatusLabel, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, g_StatusLabel, OBJPROP_FONTSIZE, 10);
    
    //--- Create additional info labels
    CreateInfoLabel("DoDo_EA", "EA: " + InpEAName, 30, 60);
    CreateInfoLabel("DoDo_Symbol", "Symbol: " + g_CurrentPair, 30, 80);
    CreateInfoLabel("DoDo_Magic", "Magic: " + IntegerToString(InpMagicNumber), 30, 100);
    CreateInfoLabel("DoDo_Trading", "Trading: " + (InpEnableTrading ? "ENABLED" : "DISABLED"), 30, 120);
    CreateInfoLabel("DoDo_ATR_Signal", "ATR Signal: CALCULATING...", 30, 140);
    CreateInfoLabel("DoDo_Spread", "Spread: 0", 30, 160);
    CreateInfoLabel("DoDo_Time", "Time: " + TimeToString(TimeCurrent()), 30, 180);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create info label                                               |
//+------------------------------------------------------------------+
void CreateInfoLabel(string name, string text, int x, int y)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
}

//+------------------------------------------------------------------+
//| Update dashboard                                                |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    //--- Update status
    color status_color = InpEnableTrading ? clrLime : clrOrange;
    string status_text = InpEnableTrading ? "TRADING ACTIVE" : "MONITORING ONLY";
    ObjectSetString(0, g_StatusLabel, OBJPROP_TEXT, "DoDo Expert Advisor - " + status_text);
    ObjectSetInteger(0, g_StatusLabel, OBJPROP_COLOR, status_color);
    
    //--- Update information
    ObjectSetString(0, "DoDo_ATR_Signal", OBJPROP_TEXT, "ATR Signal: " + g_ATRSignal);
    ObjectSetString(0, "DoDo_Spread", OBJPROP_TEXT, "Spread: " + DoubleToString(g_CurrentSpread, 1));
    ObjectSetString(0, "DoDo_Time", OBJPROP_TEXT, "Time: " + TimeToString(TimeCurrent(), TIME_MINUTES));
    
    ChartRedraw();
}