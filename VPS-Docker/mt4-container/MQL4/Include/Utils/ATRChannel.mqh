//+------------------------------------------------------------------+
//|                                                   ATRChannel.mqh |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"

//--- ATR Channel values enum
enum ENUM_ATR_CHANNEL_VALUES
{
    ATR_CHANNEL_TOP = 0,
    ATR_CHANNEL_BOTTOM = 1
};

//--- ATR Channel signal enum
enum ENUM_ATR_CHANNEL_SIGNAL
{
    ATR_SIGNAL_NONE = 0,
    ATR_SIGNAL_BUY = 1,
    ATR_SIGNAL_SELL = -1
};

//--- ATR Channel structure
struct SATRChannelData
{
    double top_line;
    double bottom_line;
    double middle_line;
    double atr_value;
    ENUM_ATR_CHANNEL_SIGNAL signal;
    double channel_width;
    bool is_valid;
};

//+------------------------------------------------------------------+
//| ATR Channel Strategy Class                                       |
//+------------------------------------------------------------------+
class CATRChannel
{
private:
    int                 m_ATRPeriod;
    double              m_ATRMultiplier;
    int                 m_LookbackPeriod;
    ENUM_TIMEFRAMES     m_Timeframe;
    string              m_Symbol;
    bool                m_IsInitialized;
    
    //--- Channel data
    SATRChannelData     m_CurrentChannel;
    SATRChannelData     m_PreviousChannel;
    
    //--- Strategy settings
    bool                m_UseBreakoutStrategy;
    bool                m_UseReversalStrategy;
    double              m_MinChannelWidth;
    int                 m_SignalConfirmationBars;
    
public:
                        CATRChannel();
                       ~CATRChannel();
    
    //--- Initialization
    bool                Initialize(string symbol, ENUM_TIMEFRAMES timeframe, 
                                   int atr_period = 14, double atr_multiplier = 2.0);
    void                Deinitialize();
    
    //--- Main calculation methods
    bool                CalculateATRChannel(int shift = 0);
    SATRChannelData     GetChannelData(int shift = 0);
    ENUM_ATR_CHANNEL_SIGNAL GetSignal();
    
    //--- Strategy methods
    bool                IsBreakoutBuy();
    bool                IsBreakoutSell();
    bool                IsReversalBuy();
    bool                IsReversalSell();
    
    //--- Configuration
    void                SetATRPeriod(int period);
    void                SetATRMultiplier(double multiplier);
    void                SetUseBreakoutStrategy(bool enable);
    void                SetUseReversalStrategy(bool enable);
    void                SetMinChannelWidth(double width);
    
    //--- Utility methods
    double              GetChannelWidth();
    double              GetCurrentATR();
    bool                IsPriceAboveChannel();
    bool                IsPriceBelowChannel();
    bool                IsPriceInChannel();
    
private:
    //--- Internal calculation methods
    double              CalculateATR(int period, int shift = 0);
    double              GetHighestHigh(int period, int shift = 0);
    double              GetLowestLow(int period, int shift = 0);
    bool                ValidateChannelData(SATRChannelData &data);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CATRChannel::CATRChannel()
{
    m_ATRPeriod = 14;
    m_ATRMultiplier = 2.0;
    m_LookbackPeriod = 20;
    m_Timeframe = PERIOD_CURRENT;
    m_Symbol = "";
    m_IsInitialized = false;
    
    m_UseBreakoutStrategy = true;
    m_UseReversalStrategy = false;
    m_MinChannelWidth = 0.0;
    m_SignalConfirmationBars = 1;
    
    //--- Initialize channel data
    ZeroMemory(m_CurrentChannel);
    ZeroMemory(m_PreviousChannel);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CATRChannel::~CATRChannel()
{
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize ATR Channel                                           |
//+------------------------------------------------------------------+
bool CATRChannel::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, 
                             int atr_period = 14, double atr_multiplier = 2.0)
{
    m_Symbol = symbol;
    m_Timeframe = timeframe;
    m_ATRPeriod = atr_period;
    m_ATRMultiplier = atr_multiplier;
    
    //--- Validate parameters
    if(m_ATRPeriod < 1 || m_ATRMultiplier <= 0)
    {
        Print("ERROR: Invalid ATR Channel parameters");
        return false;
    }
    
    //--- Calculate initial channel
    if(!CalculateATRChannel(1))
    {
        Print("ERROR: Failed to calculate initial ATR Channel");
        return false;
    }
    
    m_IsInitialized = true;
    Print("ATR Channel initialized - Period: ", m_ATRPeriod, ", Multiplier: ", m_ATRMultiplier);
    
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                     |
//+------------------------------------------------------------------+
void CATRChannel::Deinitialize()
{
    m_IsInitialized = false;
}

//+------------------------------------------------------------------+
//| Calculate ATR Channel                                            |
//+------------------------------------------------------------------+
bool CATRChannel::CalculateATRChannel(int shift = 0)
{
    if(!m_IsInitialized) return false;
    
    //--- Store previous channel data
    m_PreviousChannel = m_CurrentChannel;
    
    //--- Calculate ATR
    double atr = CalculateATR(m_ATRPeriod, shift);
    if(atr <= 0) return false;
    
    //--- Get price data
    double high = iHigh(m_Symbol, m_Timeframe, shift);
    double low = iLow(m_Symbol, m_Timeframe, shift);
    double close = iClose(m_Symbol, m_Timeframe, shift);
    
    //--- Calculate channel middle line (using moving average of highs and lows)
    double highest = GetHighestHigh(m_LookbackPeriod, shift);
    double lowest = GetLowestLow(m_LookbackPeriod, shift);
    double middle = (highest + lowest) / 2.0;
    
    //--- Calculate channel lines
    m_CurrentChannel.middle_line = middle;
    m_CurrentChannel.top_line = middle + (atr * m_ATRMultiplier);
    m_CurrentChannel.bottom_line = middle - (atr * m_ATRMultiplier);
    m_CurrentChannel.atr_value = atr;
    m_CurrentChannel.channel_width = m_CurrentChannel.top_line - m_CurrentChannel.bottom_line;
    
    //--- Validate channel data
    m_CurrentChannel.is_valid = ValidateChannelData(m_CurrentChannel);
    
    //--- Generate signal
    m_CurrentChannel.signal = GetSignal();
    
    return m_CurrentChannel.is_valid;
}

//+------------------------------------------------------------------+
//| Get channel data                                                 |
//+------------------------------------------------------------------+
SATRChannelData CATRChannel::GetChannelData(int shift = 0)
{
    if(shift == 0)
        return m_CurrentChannel;
    else
    {
        //--- Calculate for specific shift
        SATRChannelData temp_data;
        ZeroMemory(temp_data);
        
        double atr = CalculateATR(m_ATRPeriod, shift);
        if(atr > 0)
        {
            double highest = GetHighestHigh(m_LookbackPeriod, shift);
            double lowest = GetLowestLow(m_LookbackPeriod, shift);
            double middle = (highest + lowest) / 2.0;
            
            temp_data.middle_line = middle;
            temp_data.top_line = middle + (atr * m_ATRMultiplier);
            temp_data.bottom_line = middle - (atr * m_ATRMultiplier);
            temp_data.atr_value = atr;
            temp_data.channel_width = temp_data.top_line - temp_data.bottom_line;
            temp_data.is_valid = ValidateChannelData(temp_data);
        }
        
        return temp_data;
    }
}

//+------------------------------------------------------------------+
//| Get trading signal                                               |
//+------------------------------------------------------------------+
ENUM_ATR_CHANNEL_SIGNAL CATRChannel::GetSignal()
{
    if(!m_IsInitialized || !m_CurrentChannel.is_valid) 
        return ATR_SIGNAL_NONE;
    
    ENUM_ATR_CHANNEL_SIGNAL signal = ATR_SIGNAL_NONE;
    
    //--- Breakout strategy
    if(m_UseBreakoutStrategy)
    {
        if(IsBreakoutBuy())
            signal = ATR_SIGNAL_BUY;
        else if(IsBreakoutSell())
            signal = ATR_SIGNAL_SELL;
    }
    
    //--- Reversal strategy (if no breakout signal)
    if(signal == ATR_SIGNAL_NONE && m_UseReversalStrategy)
    {
        if(IsReversalBuy())
            signal = ATR_SIGNAL_BUY;
        else if(IsReversalSell())
            signal = ATR_SIGNAL_SELL;
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Check for breakout buy signal                                   |
//+------------------------------------------------------------------+
bool CATRChannel::IsBreakoutBuy()
{
    double current_close = iClose(m_Symbol, m_Timeframe, 0);
    double previous_close = iClose(m_Symbol, m_Timeframe, 1);
    
    //--- Price breaks above top channel
    bool current_above = current_close > m_CurrentChannel.top_line;
    bool previous_below = previous_close <= m_PreviousChannel.top_line;
    
    //--- Check channel width requirement
    bool width_ok = (m_MinChannelWidth <= 0) || (m_CurrentChannel.channel_width >= m_MinChannelWidth);
    
    return current_above && previous_below && width_ok;
}

//+------------------------------------------------------------------+
//| Check for breakout sell signal                                  |
//+------------------------------------------------------------------+
bool CATRChannel::IsBreakoutSell()
{
    double current_close = iClose(m_Symbol, m_Timeframe, 0);
    double previous_close = iClose(m_Symbol, m_Timeframe, 1);
    
    //--- Price breaks below bottom channel
    bool current_below = current_close < m_CurrentChannel.bottom_line;
    bool previous_above = previous_close >= m_PreviousChannel.bottom_line;
    
    //--- Check channel width requirement
    bool width_ok = (m_MinChannelWidth <= 0) || (m_CurrentChannel.channel_width >= m_MinChannelWidth);
    
    return current_below && previous_above && width_ok;
}

//+------------------------------------------------------------------+
//| Check for reversal buy signal                                   |
//+------------------------------------------------------------------+
bool CATRChannel::IsReversalBuy()
{
    double current_close = iClose(m_Symbol, m_Timeframe, 0);
    double current_low = iLow(m_Symbol, m_Timeframe, 0);
    
    //--- Price touches bottom channel and reverses
    bool touched_bottom = current_low <= m_CurrentChannel.bottom_line;
    bool closing_up = current_close > current_low;
    
    //--- Check if price is moving back into channel
    bool back_in_channel = current_close > m_CurrentChannel.bottom_line;
    
    return touched_bottom && closing_up && back_in_channel;
}

//+------------------------------------------------------------------+
//| Check for reversal sell signal                                  |
//+------------------------------------------------------------------+
bool CATRChannel::IsReversalSell()
{
    double current_close = iClose(m_Symbol, m_Timeframe, 0);
    double current_high = iHigh(m_Symbol, m_Timeframe, 0);
    
    //--- Price touches top channel and reverses
    bool touched_top = current_high >= m_CurrentChannel.top_line;
    bool closing_down = current_close < current_high;
    
    //--- Check if price is moving back into channel
    bool back_in_channel = current_close < m_CurrentChannel.top_line;
    
    return touched_top && closing_down && back_in_channel;
}

//+------------------------------------------------------------------+
//| Calculate ATR                                                   |
//+------------------------------------------------------------------+
double CATRChannel::CalculateATR(int period, int shift = 0)
{
    double atr_sum = 0.0;
    
    for(int i = shift; i < shift + period; i++)
    {
        double high = iHigh(m_Symbol, m_Timeframe, i);
        double low = iLow(m_Symbol, m_Timeframe, i);
        double prev_close = iClose(m_Symbol, m_Timeframe, i + 1);
        
        double tr1 = high - low;
        double tr2 = MathAbs(high - prev_close);
        double tr3 = MathAbs(low - prev_close);
        
        double true_range = MathMax(tr1, MathMax(tr2, tr3));
        atr_sum += true_range;
    }
    
    return atr_sum / period;
}

//+------------------------------------------------------------------+
//| Get highest high                                                |
//+------------------------------------------------------------------+
double CATRChannel::GetHighestHigh(int period, int shift = 0)
{
    double highest = iHigh(m_Symbol, m_Timeframe, shift);
    
    for(int i = shift + 1; i < shift + period; i++)
    {
        double high = iHigh(m_Symbol, m_Timeframe, i);
        if(high > highest)
            highest = high;
    }
    
    return highest;
}

//+------------------------------------------------------------------+
//| Get lowest low                                                  |
//+------------------------------------------------------------------+
double CATRChannel::GetLowestLow(int period, int shift = 0)
{
    double lowest = iLow(m_Symbol, m_Timeframe, shift);
    
    for(int i = shift + 1; i < shift + period; i++)
    {
        double low = iLow(m_Symbol, m_Timeframe, i);
        if(low < lowest)
            lowest = low;
    }
    
    return lowest;
}

//+------------------------------------------------------------------+
//| Validate channel data                                           |
//+------------------------------------------------------------------+
bool CATRChannel::ValidateChannelData(SATRChannelData &data)
{
    //--- Basic validation
    if(data.top_line <= data.bottom_line) return false;
    if(data.atr_value <= 0) return false;
    if(data.channel_width <= 0) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get channel width                                               |
//+------------------------------------------------------------------+
double CATRChannel::GetChannelWidth()
{
    return m_CurrentChannel.channel_width;
}

//+------------------------------------------------------------------+
//| Get current ATR                                                 |
//+------------------------------------------------------------------+
double CATRChannel::GetCurrentATR()
{
    return m_CurrentChannel.atr_value;
}

//+------------------------------------------------------------------+
//| Check if price is above channel                                 |
//+------------------------------------------------------------------+
bool CATRChannel::IsPriceAboveChannel()
{
    double current_close = iClose(m_Symbol, m_Timeframe, 0);
    return current_close > m_CurrentChannel.top_line;
}

//+------------------------------------------------------------------+
//| Check if price is below channel                                 |
//+------------------------------------------------------------------+
bool CATRChannel::IsPriceBelowChannel()
{
    double current_close = iClose(m_Symbol, m_Timeframe, 0);
    return current_close < m_CurrentChannel.bottom_line;
}

//+------------------------------------------------------------------+
//| Check if price is in channel                                    |
//+------------------------------------------------------------------+
bool CATRChannel::IsPriceInChannel()
{
    double current_close = iClose(m_Symbol, m_Timeframe, 0);
    return (current_close >= m_CurrentChannel.bottom_line && current_close <= m_CurrentChannel.top_line);
}

//+------------------------------------------------------------------+
//| Configuration methods                                           |
//+------------------------------------------------------------------+
void CATRChannel::SetATRPeriod(int period)
{
    if(period > 0) m_ATRPeriod = period;
}

void CATRChannel::SetATRMultiplier(double multiplier)
{
    if(multiplier > 0) m_ATRMultiplier = multiplier;
}

void CATRChannel::SetUseBreakoutStrategy(bool enable)
{
    m_UseBreakoutStrategy = enable;
}

void CATRChannel::SetUseReversalStrategy(bool enable)
{
    m_UseReversalStrategy = enable;
}

void CATRChannel::SetMinChannelWidth(double width)
{
    m_MinChannelWidth = MathMax(0, width);
}