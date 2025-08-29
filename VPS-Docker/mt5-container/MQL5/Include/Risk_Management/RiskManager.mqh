//+------------------------------------------------------------------+
//|                                                 RiskManager.mqh |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"

//--- Risk management structure
struct SRiskSettings
{
    double max_risk_percent;
    double max_lot_size;
    double min_lot_size;
    int max_positions;
    double max_drawdown_percent;
    bool use_fixed_lot;
    double fixed_lot_size;
    int stop_loss_pips;
    int take_profit_pips;
    bool use_trailing_stop;
    int trailing_distance;
};

//+------------------------------------------------------------------+
//| Risk Manager Class                                              |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    SRiskSettings       m_Settings;
    double              m_BaseLotSize;
    ulong               m_MagicNumber;
    bool                m_IsInitialized;
    
public:
                        CRiskManager();
                       ~CRiskManager();
    
    bool                Initialize(double base_lot, ulong magic);
    void                Deinitialize();
    
    //--- Position sizing
    double              CalculateLotSize();
    double              CalculateRiskBasedLot(double stop_loss_pips);
    
    //--- Risk validation
    bool                CanOpenTrade(int order_type);
    bool                ValidateRisk();
    
    //--- Stop loss / Take profit
    double              CalculateStopLoss(int order_type, double entry_price);
    double              CalculateTakeProfit(int order_type, double entry_price);
    
    //--- Position management
    void                CloseAllTrades();
    double              GetCurrentRisk();
    
    //--- Settings
    void                SetRiskSettings(SRiskSettings &settings);
    SRiskSettings       GetRiskSettings() { return m_Settings; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
    m_IsInitialized = false;
    m_BaseLotSize = 0.1;
    m_MagicNumber = 0;
    
    //--- Default settings
    m_Settings.max_risk_percent = 2.0;
    m_Settings.max_lot_size = 1.0;
    m_Settings.min_lot_size = 0.01;
    m_Settings.max_positions = 5;
    m_Settings.max_drawdown_percent = 20.0;
    m_Settings.use_fixed_lot = false;
    m_Settings.fixed_lot_size = 0.1;
    m_Settings.stop_loss_pips = 50;
    m_Settings.take_profit_pips = 100;
    m_Settings.use_trailing_stop = true;
    m_Settings.trailing_distance = 30;
}

//+------------------------------------------------------------------+
//| Initialize risk manager                                          |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(double base_lot, ulong magic)
{
    m_BaseLotSize = base_lot;
    m_MagicNumber = magic;
    m_IsInitialized = true;
    
    Print("Risk Manager initialized - Base Lot: ", base_lot, ", Magic: ", magic);
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size                                              |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize()
{
    if(!m_IsInitialized) return 0.01;
    
    if(m_Settings.use_fixed_lot)
        return m_Settings.fixed_lot_size;
    
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (m_Settings.max_risk_percent / 100.0);
    
    double lot_size = risk_amount / (m_Settings.stop_loss_pips * 10.0);
    
    //--- Apply limits
    lot_size = MathMax(m_Settings.min_lot_size, lot_size);
    lot_size = MathMin(m_Settings.max_lot_size, lot_size);
    
    return NormalizeDouble(lot_size, 2);
}

//+------------------------------------------------------------------+
//| Check if can open trade                                         |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenTrade(int order_type)
{
    if(!m_IsInitialized) return false;
    
    //--- Check max positions
    #ifdef __MQL5__
    if(PositionsTotal() >= m_Settings.max_positions) return false;
    #else
    int open_orders = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == m_MagicNumber) open_orders++;
        }
    }
    if(open_orders >= m_Settings.max_positions) return false;
    #endif
    
    //--- Check drawdown
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double drawdown_percent = ((balance - equity) / balance) * 100.0;
    
    if(drawdown_percent > m_Settings.max_drawdown_percent) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                             |
//+------------------------------------------------------------------+
double CRiskManager::CalculateStopLoss(int order_type, double entry_price)
{
    double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    double sl_distance = m_Settings.stop_loss_pips * point;
    
    #ifdef __MQL5__
    if(order_type == ORDER_TYPE_BUY)
        return entry_price - sl_distance;
    else
        return entry_price + sl_distance;
    #else
    if(order_type == OP_BUY)
        return entry_price - sl_distance;
    else
        return entry_price + sl_distance;
    #endif
}

//+------------------------------------------------------------------+
//| Calculate take profit                                           |
//+------------------------------------------------------------------+
double CRiskManager::CalculateTakeProfit(int order_type, double entry_price)
{
    double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    double tp_distance = m_Settings.take_profit_pips * point;
    
    #ifdef __MQL5__
    if(order_type == ORDER_TYPE_BUY)
        return entry_price + tp_distance;
    else
        return entry_price - tp_distance;
    #else
    if(order_type == OP_BUY)
        return entry_price + tp_distance;
    else
        return entry_price - tp_distance;
    #endif
}

//+------------------------------------------------------------------+
//| Close all trades                                               |
//+------------------------------------------------------------------+
void CRiskManager::CloseAllTrades()
{
    #ifdef __MQL5__
    CTrade trade;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        CPositionInfo pos;
        if(pos.SelectByIndex(i))
        {
            if(pos.Magic() == m_MagicNumber)
            {
                trade.PositionClose(pos.Ticket());
            }
        }
    }
    #else
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == m_MagicNumber)
            {
                OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3);
            }
        }
    }
    #endif
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Deinitialize                                                     |
//+------------------------------------------------------------------+
void CRiskManager::Deinitialize()
{
    m_IsInitialized = false;
}