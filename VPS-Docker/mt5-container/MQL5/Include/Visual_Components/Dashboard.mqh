//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"

//--- Panel dimensions and positions
#define PANEL_WIDTH 400
#define PANEL_HEIGHT 600
#define PANEL_X 20
#define PANEL_Y 30
#define BUTTON_HEIGHT 30
#define BUTTON_WIDTH 80
#define TEXT_HEIGHT 20
#define MARGIN 10

//--- Colors
#define COLOR_PANEL_BG clrDarkBlue
#define COLOR_PANEL_BORDER clrWhite
#define COLOR_TEXT_NORMAL clrWhite
#define COLOR_TEXT_POSITIVE clrLime
#define COLOR_TEXT_NEGATIVE clrRed
#define COLOR_BUTTON_BG clrNavy
#define COLOR_BUTTON_BORDER clrSilver

//+------------------------------------------------------------------+
//| Dashboard class for visual interface                             |
//+------------------------------------------------------------------+
class CDashboard
{
private:
    color               m_PanelColor;
    bool                m_IsVisible;
    int                 m_CurrentY;
    
    //--- Object names
    string              m_MainPanel;
    string              m_StatusLabel;
    string              m_AIPanel;
    string              m_NewsPanel;
    string              m_TradePanel;
    string              m_ControlPanel;
    
    //--- Control buttons
    string              m_BtnToggleTrading;
    string              m_BtnRefreshAI;
    string              m_BtnCloseAll;
    string              m_BtnSettings;
    
public:
                        CDashboard();
                       ~CDashboard();
    
    bool                Initialize(color panel_color = COLOR_PANEL_BG);
    void                Deinitialize();
    
    //--- Main update functions
    void                UpdateStatus(string status, color status_color);
    void                UpdateInfo(string label, string value);
    void                UpdateAIAnalysis(SAIAnalysis &analysis);
    void                UpdateTradeInfo(MqlTradeTransaction &trans, MqlTradeResult &result);
    
    //--- Event handling
    void                OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
    
    //--- Visibility control
    void                Show();
    void                Hide();
    bool                IsVisible() { return m_IsVisible; }
    
private:
    //--- Panel creation functions
    bool                CreateMainPanel();
    bool                CreateStatusSection();
    bool                CreateAISection();
    bool                CreateATRChannelSection();
    bool                CreateNewsSection();
    bool                CreateTradeSection();
    bool                CreateControlSection();
    
    //--- Helper functions
    void                CreateLabel(string name, string text, int x, int y, int width, int height, color text_color = COLOR_TEXT_NORMAL);
    void                CreateButton(string name, string text, int x, int y, int width, int height);
    void                CreateEditBox(string name, string text, int x, int y, int width, int height);
    void                UpdateLabel(string name, string text, color text_color = COLOR_TEXT_NORMAL);
    
    //--- Button event handlers
    void                OnToggleTrading();
    void                OnRefreshAI();
    void                OnCloseAll();
    void                OnSettings();
    
    //--- Utility functions
    string              GenerateObjectName(string prefix);
    void                SetObjectPosition(string name, int x, int y);
    void                DeleteAllObjects();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDashboard::CDashboard()
{
    m_PanelColor = COLOR_PANEL_BG;
    m_IsVisible = false;
    m_CurrentY = PANEL_Y + MARGIN;
    
    //--- Initialize object names
    m_MainPanel = GenerateObjectName("AI_MainPanel");
    m_StatusLabel = GenerateObjectName("AI_Status");
    m_AIPanel = GenerateObjectName("AI_Panel");
    m_NewsPanel = GenerateObjectName("AI_News");
    m_TradePanel = GenerateObjectName("AI_Trade");
    m_ControlPanel = GenerateObjectName("AI_Control");
    
    m_BtnToggleTrading = GenerateObjectName("AI_BtnTrade");
    m_BtnRefreshAI = GenerateObjectName("AI_BtnRefresh");
    m_BtnCloseAll = GenerateObjectName("AI_BtnClose");
    m_BtnSettings = GenerateObjectName("AI_BtnSettings");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDashboard::~CDashboard()
{
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize dashboard                                             |
//+------------------------------------------------------------------+
bool CDashboard::Initialize(color panel_color = COLOR_PANEL_BG)
{
    m_PanelColor = panel_color;
    
    //--- Create main panel
    if(!CreateMainPanel())
        return false;
    
    //--- Create sections
    if(!CreateStatusSection())
        return false;
        
    if(!CreateAISection())
        return false;
        
    if(!CreateATRChannelSection())
        return false;
        
    if(!CreateNewsSection())
        return false;
        
    if(!CreateTradeSection())
        return false;
        
    if(!CreateControlSection())
        return false;
    
    m_IsVisible = true;
    ChartRedraw();
    
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize dashboard                                           |
//+------------------------------------------------------------------+
void CDashboard::Deinitialize()
{
    DeleteAllObjects();
    m_IsVisible = false;
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create main panel                                                |
//+------------------------------------------------------------------+
bool CDashboard::CreateMainPanel()
{
    //--- Main panel background
    if(!ObjectCreate(0, m_MainPanel, OBJ_RECTANGLE_LABEL, 0, 0, 0))
        return false;
    
    ObjectSetInteger(0, m_MainPanel, OBJPROP_XDISTANCE, PANEL_X);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_YDISTANCE, PANEL_Y);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_XSIZE, PANEL_WIDTH);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_YSIZE, PANEL_HEIGHT);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_COLOR, COLOR_PANEL_BORDER);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_BGCOLOR, m_PanelColor);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_BACK, false);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, m_MainPanel, OBJPROP_HIDDEN, true);
    
    //--- Panel title
    CreateLabel(GenerateObjectName("AI_Title"), "AI Trading Expert Dashboard", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT, clrYellow);
    m_CurrentY += TEXT_HEIGHT + MARGIN;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create status section                                            |
//+------------------------------------------------------------------+
bool CDashboard::CreateStatusSection()
{
    //--- Section title
    CreateLabel(GenerateObjectName("AI_StatusTitle"), "=== STATUS ===", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT, clrCyan);
    m_CurrentY += TEXT_HEIGHT + MARGIN/2;
    
    //--- Status labels
    CreateLabel(m_StatusLabel, "Status: INITIALIZING", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_EA"), "EA: Loading...", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Symbol"), "Symbol: " + Symbol(), 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Spread"), "Spread: 0.0", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Balance"), "Balance: $0.00", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Equity"), "Equity: $0.00", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + MARGIN;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create AI analysis section                                       |
//+------------------------------------------------------------------+
bool CDashboard::CreateAISection()
{
    //--- Section title
    CreateLabel(GenerateObjectName("AI_AITitle"), "=== AI ANALYSIS ===", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT, clrCyan);
    m_CurrentY += TEXT_HEIGHT + MARGIN/2;
    
    //--- AI analysis labels
    CreateLabel(GenerateObjectName("AI_Sentiment"), "Sentiment: Analyzing...", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Recommendation"), "Recommendation: HOLD", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Confidence"), "Confidence: 0%", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Risk"), "Risk Score: N/A", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_Target"), "Price Target: N/A", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + MARGIN;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create ATR Channel section                                       |
//+------------------------------------------------------------------+
bool CDashboard::CreateATRChannelSection()
{
    //--- Section title
    CreateLabel(GenerateObjectName("AI_ATRTitle"), "=== ATR CHANNEL ===", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT, clrCyan);
    m_CurrentY += TEXT_HEIGHT + MARGIN/2;
    
    //--- ATR Channel labels
    CreateLabel(GenerateObjectName("AI_ATRSignal"), "Signal: NONE", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_ATRTop"), "Top Line: 0.00000", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_ATRBottom"), "Bottom Line: 0.00000", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_ATRWidth"), "Channel Width: 0.00000", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_ATRPosition"), "Position: IN CHANNEL", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + MARGIN;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create news section                                              |
//+------------------------------------------------------------------+
bool CDashboard::CreateNewsSection()
{
    //--- Section title
    CreateLabel(GenerateObjectName("AI_NewsTitle"), "=== NEWS & SENTIMENT ===", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT, clrCyan);
    m_CurrentY += TEXT_HEIGHT + MARGIN/2;
    
    //--- News analysis box (multiline)
    CreateEditBox(GenerateObjectName("AI_NewsSummary"), "Loading news analysis...", 
                  PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, 60);
    m_CurrentY += 60 + 5;
    
    CreateLabel(GenerateObjectName("AI_Social"), "Social Sentiment: Analyzing...", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_LastUpdate"), "Last Update: Never", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + MARGIN;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create trade section                                             |
//+------------------------------------------------------------------+
bool CDashboard::CreateTradeSection()
{
    //--- Section title
    CreateLabel(GenerateObjectName("AI_TradeTitle"), "=== TRADE INFO ===", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT, clrCyan);
    m_CurrentY += TEXT_HEIGHT + MARGIN/2;
    
    //--- Trade information
    CreateLabel(GenerateObjectName("AI_Positions"), "Open Positions: 0", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_PnL"), "Today's P&L: $0.00", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + 5;
    
    CreateLabel(GenerateObjectName("AI_LastTrade"), "Last Trade: None", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT);
    m_CurrentY += TEXT_HEIGHT + MARGIN;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create control section                                           |
//+------------------------------------------------------------------+
bool CDashboard::CreateControlSection()
{
    //--- Section title
    CreateLabel(GenerateObjectName("AI_ControlTitle"), "=== CONTROLS ===", 
                PANEL_X + MARGIN, m_CurrentY, PANEL_WIDTH - 2*MARGIN, TEXT_HEIGHT, clrCyan);
    m_CurrentY += TEXT_HEIGHT + MARGIN/2;
    
    //--- Control buttons
    CreateButton(m_BtnToggleTrading, "Trading ON", 
                 PANEL_X + MARGIN, m_CurrentY, BUTTON_WIDTH, BUTTON_HEIGHT);
                 
    CreateButton(m_BtnRefreshAI, "Refresh AI", 
                 PANEL_X + MARGIN + BUTTON_WIDTH + 10, m_CurrentY, BUTTON_WIDTH, BUTTON_HEIGHT);
    m_CurrentY += BUTTON_HEIGHT + 10;
    
    CreateButton(m_BtnCloseAll, "Close All", 
                 PANEL_X + MARGIN, m_CurrentY, BUTTON_WIDTH, BUTTON_HEIGHT);
                 
    CreateButton(m_BtnSettings, "Settings", 
                 PANEL_X + MARGIN + BUTTON_WIDTH + 10, m_CurrentY, BUTTON_WIDTH, BUTTON_HEIGHT);
    m_CurrentY += BUTTON_HEIGHT + MARGIN;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create label                                                     |
//+------------------------------------------------------------------+
void CDashboard::CreateLabel(string name, string text, int x, int y, int width, int height, color text_color = COLOR_TEXT_NORMAL)
{
    if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    }
}

//+------------------------------------------------------------------+
//| Create button                                                    |
//+------------------------------------------------------------------+
void CDashboard::CreateButton(string name, string text, int x, int y, int width, int height)
{
    if(ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
    {
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_TEXT_NORMAL);
        ObjectSetInteger(0, name, OBJPROP_BGCOLOR, COLOR_BUTTON_BG);
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, COLOR_BUTTON_BORDER);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, name, OBJPROP_STATE, false);
    }
}

//+------------------------------------------------------------------+
//| Create edit box                                                  |
//+------------------------------------------------------------------+
void CDashboard::CreateEditBox(string name, string text, int x, int y, int width, int height)
{
    if(ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0))
    {
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_TEXT_NORMAL);
        ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrDarkSlateGray);
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, COLOR_BUTTON_BORDER);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, name, OBJPROP_READONLY, true);
    }
}

//+------------------------------------------------------------------+
//| Update label text                                                |
//+------------------------------------------------------------------+
void CDashboard::UpdateLabel(string name, string text, color text_color = COLOR_TEXT_NORMAL)
{
    if(ObjectFind(0, name) >= 0)
    {
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
    }
}

//+------------------------------------------------------------------+
//| Update status                                                    |
//+------------------------------------------------------------------+
void CDashboard::UpdateStatus(string status, color status_color)
{
    UpdateLabel(m_StatusLabel, "Status: " + status, status_color);
}

//+------------------------------------------------------------------+
//| Update information                                               |
//+------------------------------------------------------------------+
void CDashboard::UpdateInfo(string label, string value)
{
    string object_name = GenerateObjectName("AI_" + label);
    UpdateLabel(object_name, label + ": " + value);
}

//+------------------------------------------------------------------+
//| Update AI analysis                                               |
//+------------------------------------------------------------------+
void CDashboard::UpdateAIAnalysis(SAIAnalysis &analysis)
{
    if(!analysis.is_valid) return;
    
    //--- Update sentiment with color coding
    color sentiment_color = (analysis.sentiment_score > 0) ? COLOR_TEXT_POSITIVE : 
                           (analysis.sentiment_score < 0) ? COLOR_TEXT_NEGATIVE : COLOR_TEXT_NORMAL;
    UpdateLabel(GenerateObjectName("AI_Sentiment"), 
                "Sentiment: " + DoubleToString(analysis.sentiment_score, 3), sentiment_color);
    
    //--- Update recommendation with color coding
    color rec_color = COLOR_TEXT_NORMAL;
    if(StringFind(analysis.recommendation, "BUY") >= 0) rec_color = COLOR_TEXT_POSITIVE;
    else if(StringFind(analysis.recommendation, "SELL") >= 0) rec_color = COLOR_TEXT_NEGATIVE;
    
    UpdateLabel(GenerateObjectName("AI_Recommendation"), 
                "Recommendation: " + analysis.recommendation, rec_color);
    
    //--- Update confidence
    UpdateLabel(GenerateObjectName("AI_Confidence"), 
                "Confidence: " + IntegerToString((int)(analysis.confidence_level * 100)) + "%");
    
    //--- Update risk score
    color risk_color = (analysis.risk_score > 0.7) ? COLOR_TEXT_NEGATIVE : 
                      (analysis.risk_score > 0.4) ? clrOrange : COLOR_TEXT_POSITIVE;
    UpdateLabel(GenerateObjectName("AI_Risk"), 
                "Risk Score: " + DoubleToString(analysis.risk_score, 2), risk_color);
    
    //--- Update price target
    if(analysis.price_target > 0)
    {
        UpdateLabel(GenerateObjectName("AI_Target"), 
                    "Price Target: " + DoubleToString(analysis.price_target, 5));
    }
    
    //--- Update news summary
    if(analysis.news_summary != "")
    {
        ObjectSetString(0, GenerateObjectName("AI_NewsSummary"), OBJPROP_TEXT, analysis.news_summary);
    }
    
    //--- Update social sentiment
    UpdateLabel(GenerateObjectName("AI_Social"), 
                "Social Sentiment: " + analysis.social_sentiment);
    
    //--- Update last update time
    UpdateLabel(GenerateObjectName("AI_LastUpdate"), 
                "Last Update: " + TimeToString(analysis.last_update, TIME_MINUTES));
    
    //--- Update ATR Channel information
    if(analysis.atr_signal != "")
    {
        color signal_color = COLOR_TEXT_NORMAL;
        if(analysis.atr_signal == "BUY") signal_color = COLOR_TEXT_POSITIVE;
        else if(analysis.atr_signal == "SELL") signal_color = COLOR_TEXT_NEGATIVE;
        
        UpdateLabel(GenerateObjectName("AI_ATRSignal"), 
                    "Signal: " + analysis.atr_signal, signal_color);
        
        UpdateLabel(GenerateObjectName("AI_ATRTop"), 
                    "Top Line: " + DoubleToString(analysis.atr_top_line, 5));
        
        UpdateLabel(GenerateObjectName("AI_ATRBottom"), 
                    "Bottom Line: " + DoubleToString(analysis.atr_bottom_line, 5));
        
        UpdateLabel(GenerateObjectName("AI_ATRWidth"), 
                    "Channel Width: " + DoubleToString(analysis.atr_channel_width, 5));
        
        string position = "IN CHANNEL";
        color pos_color = COLOR_TEXT_NORMAL;
        
        if(analysis.atr_above_channel)
        {
            position = "ABOVE CHANNEL";
            pos_color = COLOR_TEXT_POSITIVE;
        }
        else if(analysis.atr_below_channel)
        {
            position = "BELOW CHANNEL";
            pos_color = COLOR_TEXT_NEGATIVE;
        }
        
        UpdateLabel(GenerateObjectName("AI_ATRPosition"), 
                    "Position: " + position, pos_color);
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update trade information                                         |
//+------------------------------------------------------------------+
void CDashboard::UpdateTradeInfo(MqlTradeTransaction &trans, MqlTradeResult &result)
{
    #ifdef __MQL5__
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        string trade_type = (trans.order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
        UpdateLabel(GenerateObjectName("AI_LastTrade"), 
                    "Last Trade: " + trade_type + " " + DoubleToString(trans.volume, 2));
    }
    #endif
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Handle chart events                                              |
//+------------------------------------------------------------------+
void CDashboard::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == m_BtnToggleTrading)
        {
            OnToggleTrading();
        }
        else if(sparam == m_BtnRefreshAI)
        {
            OnRefreshAI();
        }
        else if(sparam == m_BtnCloseAll)
        {
            OnCloseAll();
        }
        else if(sparam == m_BtnSettings)
        {
            OnSettings();
        }
        
        //--- Reset button state
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
//| Toggle trading button handler                                   |
//+------------------------------------------------------------------+
void CDashboard::OnToggleTrading()
{
    // This will be handled by the main EA
    Print("Toggle trading button clicked");
}

//+------------------------------------------------------------------+
//| Refresh AI button handler                                       |
//+------------------------------------------------------------------+
void CDashboard::OnRefreshAI()
{
    // This will trigger AI analysis refresh
    Print("Refresh AI button clicked");
}

//+------------------------------------------------------------------+
//| Close all positions button handler                              |
//+------------------------------------------------------------------+
void CDashboard::OnCloseAll()
{
    // This will close all positions
    Print("Close all positions button clicked");
}

//+------------------------------------------------------------------+
//| Settings button handler                                         |
//+------------------------------------------------------------------+
void CDashboard::OnSettings()
{
    // This will open settings dialog
    Print("Settings button clicked");
}

//+------------------------------------------------------------------+
//| Show dashboard                                                   |
//+------------------------------------------------------------------+
void CDashboard::Show()
{
    m_IsVisible = true;
    // Set all objects visible
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Hide dashboard                                                   |
//+------------------------------------------------------------------+
void CDashboard::Hide()
{
    m_IsVisible = false;
    // Set all objects invisible
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Generate unique object name                                      |
//+------------------------------------------------------------------+
string CDashboard::GenerateObjectName(string prefix)
{
    return prefix + "_" + IntegerToString(ChartID());
}

//+------------------------------------------------------------------+
//| Delete all dashboard objects                                     |
//+------------------------------------------------------------------+
void CDashboard::DeleteAllObjects()
{
    ObjectsDeleteAll(0, "AI_");
}