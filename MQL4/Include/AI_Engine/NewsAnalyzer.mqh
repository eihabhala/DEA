//+------------------------------------------------------------------+
//|                                                NewsAnalyzer.mqh |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"

//--- News analysis structure
struct SNewsItem
{
    string title;
    string description;
    string category;
    string country;
    datetime timestamp;
    int importance; // 1-3 (low, medium, high)
    double impact_score; // -1.0 to 1.0
    string currency;
    bool is_processed;
};

//--- Analysis result structure
struct SNewsAnalysis
{
    double sentiment_score; // -1.0 to 1.0
    string summary;
    double confidence;
    string key_events;
    datetime last_analysis;
    int news_count;
    double volatility_forecast;
    string recommendation;
};

//--- News sources configuration
enum ENUM_NEWS_SOURCE
{
    NEWS_SOURCE_FOREX_FACTORY,
    NEWS_SOURCE_ECONOMIC_CALENDAR,
    NEWS_SOURCE_RSS_FEEDS,
    NEWS_SOURCE_API_FEEDS
};

//+------------------------------------------------------------------+
//| News Analyzer Class                                              |
//+------------------------------------------------------------------+
class CNewsAnalyzer
{
private:
    SNewsItem           m_NewsItems[];
    SNewsAnalysis       m_LastAnalysis;
    datetime            m_LastUpdate;
    string              m_APIKey;
    string              m_NewsURL;
    bool                m_IsInitialized;
    
    //--- Configuration
    int                 m_MaxNewsItems;
    int                 m_AnalysisHours;
    ENUM_NEWS_SOURCE    m_NewsSource;
    
    //--- AI sentiment keywords
    string              m_PositiveKeywords[];
    string              m_NegativeKeywords[];
    string              m_CurrencyPairs[];
    
public:
                        CNewsAnalyzer();
                       ~CNewsAnalyzer();
    
    //--- Initialization
    bool                Initialize(string api_key = "");
    void                Deinitialize();
    
    //--- Main analysis functions
    SNewsAnalysis       AnalyzeLatestNews(string symbol);
    bool                FetchLatestNews();
    double              AnalyzeSentiment(string text);
    
    //--- News processing
    bool                ProcessNewsItem(SNewsItem &item);
    double              CalculateImpactScore(SNewsItem &item);
    string              GenerateSummary(SNewsItem &items[]);
    
    //--- Configuration
    void                SetNewsSource(ENUM_NEWS_SOURCE source);
    void                SetAnalysisTimeframe(int hours);
    void                SetAPIKey(string key);
    
    //--- Utility functions
    bool                IsRelevantForSymbol(SNewsItem &item, string symbol);
    string              ExtractCurrencyFromSymbol(string symbol);
    double              GetVolatilityForecast(SNewsItem &items[]);
    
private:
    //--- Internal methods
    bool                InitializeKeywords();
    bool                FetchFromForexFactory();
    bool                FetchFromAPI();
    bool                ParseNewsData(string json_data);
    string              CleanNewsText(string text);
    double              AnalyzeTextSentiment(string text);
    int                 CountKeywordMatches(string text, string keywords[]);
    string              FormatNewsForAI(SNewsItem &items[]);
    
    //--- HTTP utilities
    string              SendHTTPRequest(string url, string headers = "");
    bool                ParseJSONResponse(string response);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewsAnalyzer::CNewsAnalyzer()
{
    m_LastUpdate = 0;
    m_IsInitialized = false;
    m_MaxNewsItems = 50;
    m_AnalysisHours = 24;
    m_NewsSource = NEWS_SOURCE_FOREX_FACTORY;
    m_APIKey = "";
    m_NewsURL = "https://nfs.faireconomy.media/ff_calendar_thisweek.json";
    
    //--- Initialize analysis structure
    m_LastAnalysis.sentiment_score = 0.0;
    m_LastAnalysis.confidence = 0.0;
    m_LastAnalysis.news_count = 0;
    m_LastAnalysis.last_analysis = 0;
    m_LastAnalysis.summary = "";
    m_LastAnalysis.key_events = "";
    m_LastAnalysis.volatility_forecast = 0.0;
    m_LastAnalysis.recommendation = "";
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CNewsAnalyzer::~CNewsAnalyzer()
{
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize the news analyzer                                     |
//+------------------------------------------------------------------+
bool CNewsAnalyzer::Initialize(string api_key = "")
{
    Print("Initializing News Analyzer...");
    
    if(api_key != "")
        m_APIKey = api_key;
    
    //--- Initialize keyword arrays
    if(!InitializeKeywords())
    {
        Print("ERROR: Failed to initialize sentiment keywords");
        return false;
    }
    
    //--- Initialize currency pairs array
    ArrayResize(m_CurrencyPairs, 28);
    m_CurrencyPairs[0] = "EUR"; m_CurrencyPairs[1] = "USD"; m_CurrencyPairs[2] = "GBP";
    m_CurrencyPairs[3] = "JPY"; m_CurrencyPairs[4] = "AUD"; m_CurrencyPairs[5] = "CAD";
    m_CurrencyPairs[6] = "CHF"; m_CurrencyPairs[7] = "NZD"; m_CurrencyPairs[8] = "SEK";
    m_CurrencyPairs[9] = "NOK"; m_CurrencyPairs[10] = "DKK"; m_CurrencyPairs[11] = "PLN";
    m_CurrencyPairs[12] = "CZK"; m_CurrencyPairs[13] = "HUF"; m_CurrencyPairs[14] = "TRY";
    m_CurrencyPairs[15] = "ZAR"; m_CurrencyPairs[16] = "MXN"; m_CurrencyPairs[17] = "SGD";
    m_CurrencyPairs[18] = "HKD"; m_CurrencyPairs[19] = "CNY"; m_CurrencyPairs[20] = "INR";
    m_CurrencyPairs[21] = "KRW"; m_CurrencyPairs[22] = "BRL"; m_CurrencyPairs[23] = "RUB";
    m_CurrencyPairs[24] = "XAU"; m_CurrencyPairs[25] = "XAG"; m_CurrencyPairs[26] = "OIL";
    m_CurrencyPairs[27] = "BTC";
    
    //--- Initialize news items array
    ArrayResize(m_NewsItems, m_MaxNewsItems);
    
    m_IsInitialized = true;
    Print("News Analyzer initialized successfully");
    
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the analyzer                                        |
//+------------------------------------------------------------------+
void CNewsAnalyzer::Deinitialize()
{
    ArrayFree(m_NewsItems);
    ArrayFree(m_PositiveKeywords);
    ArrayFree(m_NegativeKeywords);
    ArrayFree(m_CurrencyPairs);
    m_IsInitialized = false;
}

//+------------------------------------------------------------------+
//| Analyze latest news for specific symbol                         |
//+------------------------------------------------------------------+
SNewsAnalysis CNewsAnalyzer::AnalyzeLatestNews(string symbol)
{
    if(!m_IsInitialized)
    {
        Print("ERROR: News analyzer not initialized");
        return m_LastAnalysis;
    }
    
    Print("Analyzing latest news for ", symbol);
    
    //--- Fetch latest news if needed
    datetime current_time = TimeCurrent();
    if(current_time - m_LastUpdate > 3600) // Update every hour
    {
        if(!FetchLatestNews())
        {
            Print("WARNING: Failed to fetch latest news, using cached data");
        }
    }
    
    //--- Filter relevant news for symbol
    SNewsItem relevant_news[];
    int relevant_count = 0;
    
    for(int i = 0; i < ArraySize(m_NewsItems); i++)
    {
        if(m_NewsItems[i].is_processed && IsRelevantForSymbol(m_NewsItems[i], symbol))
        {
            ArrayResize(relevant_news, relevant_count + 1);
            relevant_news[relevant_count] = m_NewsItems[i];
            relevant_count++;
        }
    }
    
    //--- Perform analysis
    m_LastAnalysis.news_count = relevant_count;
    m_LastAnalysis.last_analysis = current_time;
    
    if(relevant_count > 0)
    {
        //--- Calculate overall sentiment
        double total_sentiment = 0.0;
        double total_weight = 0.0;
        
        for(int i = 0; i < relevant_count; i++)
        {
            double weight = (double)relevant_news[i].importance;
            total_sentiment += relevant_news[i].impact_score * weight;
            total_weight += weight;
        }
        
        m_LastAnalysis.sentiment_score = (total_weight > 0) ? total_sentiment / total_weight : 0.0;
        
        //--- Calculate confidence based on news count and recency
        m_LastAnalysis.confidence = MathMin(1.0, (double)relevant_count / 10.0);
        if(relevant_count > 0)
        {
            datetime latest_news = relevant_news[0].timestamp;
            for(int i = 1; i < relevant_count; i++)
            {
                if(relevant_news[i].timestamp > latest_news)
                    latest_news = relevant_news[i].timestamp;
            }
            
            double hours_old = (double)(current_time - latest_news) / 3600.0;
            double recency_factor = MathMax(0.1, 1.0 - (hours_old / 24.0));
            m_LastAnalysis.confidence *= recency_factor;
        }
        
        //--- Generate summary and forecast
        m_LastAnalysis.summary = GenerateSummary(relevant_news);
        m_LastAnalysis.volatility_forecast = GetVolatilityForecast(relevant_news);
        
        //--- Generate recommendation
        if(m_LastAnalysis.sentiment_score > 0.3 && m_LastAnalysis.confidence > 0.6)
            m_LastAnalysis.recommendation = "BULLISH";
        else if(m_LastAnalysis.sentiment_score < -0.3 && m_LastAnalysis.confidence > 0.6)
            m_LastAnalysis.recommendation = "BEARISH";
        else
            m_LastAnalysis.recommendation = "NEUTRAL";
    }
    else
    {
        m_LastAnalysis.sentiment_score = 0.0;
        m_LastAnalysis.confidence = 0.0;
        m_LastAnalysis.summary = "No relevant news found for " + symbol;
        m_LastAnalysis.recommendation = "NEUTRAL";
        m_LastAnalysis.volatility_forecast = 0.0;
    }
    
    Print("News analysis completed - Sentiment: ", DoubleToString(m_LastAnalysis.sentiment_score, 3),
          ", Confidence: ", DoubleToString(m_LastAnalysis.confidence, 3),
          ", News Count: ", IntegerToString(relevant_count));
    
    return m_LastAnalysis;
}

//+------------------------------------------------------------------+
//| Fetch latest news from configured source                        |
//+------------------------------------------------------------------+
bool CNewsAnalyzer::FetchLatestNews()
{
    Print("Fetching latest news from source...");
    
    bool success = false;
    
    switch(m_NewsSource)
    {
        case NEWS_SOURCE_FOREX_FACTORY:
            success = FetchFromForexFactory();
            break;
        case NEWS_SOURCE_API_FEEDS:
            success = FetchFromAPI();
            break;
        default:
            // Fallback to demo data for testing
            success = CreateDemoNewsData();
            break;
    }
    
    if(success)
    {
        m_LastUpdate = TimeCurrent();
        Print("News fetched successfully, ", ArraySize(m_NewsItems), " items loaded");
    }
    else
    {
        Print("Failed to fetch news from source");
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Create demo news data for testing                               |
//+------------------------------------------------------------------+
bool CNewsAnalyzer::CreateDemoNewsData()
{
    ArrayResize(m_NewsItems, 10);
    
    //--- Sample news items
    m_NewsItems[0].title = "Federal Reserve Raises Interest Rates";
    m_NewsItems[0].description = "The Federal Reserve announced a 0.25% interest rate increase to combat inflation";
    m_NewsItems[0].category = "Central Bank";
    m_NewsItems[0].country = "US";
    m_NewsItems[0].currency = "USD";
    m_NewsItems[0].importance = 3;
    m_NewsItems[0].timestamp = TimeCurrent() - 3600;
    m_NewsItems[0].impact_score = 0.6;
    m_NewsItems[0].is_processed = true;
    
    m_NewsItems[1].title = "ECB Maintains Dovish Stance";
    m_NewsItems[1].description = "European Central Bank signals continued accommodative monetary policy";
    m_NewsItems[1].category = "Central Bank";
    m_NewsItems[1].country = "EU";
    m_NewsItems[1].currency = "EUR";
    m_NewsItems[1].importance = 3;
    m_NewsItems[1].timestamp = TimeCurrent() - 7200;
    m_NewsItems[1].impact_score = -0.4;
    m_NewsItems[1].is_processed = true;
    
    m_NewsItems[2].title = "GDP Growth Exceeds Expectations";
    m_NewsItems[2].description = "US GDP growth reported at 3.2%, beating analyst expectations of 2.8%";
    m_NewsItems[2].category = "Economic Data";
    m_NewsItems[2].country = "US";
    m_NewsItems[2].currency = "USD";
    m_NewsItems[2].importance = 2;
    m_NewsItems[2].timestamp = TimeCurrent() - 10800;
    m_NewsItems[2].impact_score = 0.7;
    m_NewsItems[2].is_processed = true;
    
    m_NewsItems[3].title = "Bank of England Signals Rate Pause";
    m_NewsItems[3].description = "BoE Governor indicates potential pause in rate hiking cycle";
    m_NewsItems[3].category = "Central Bank";
    m_NewsItems[3].country = "UK";
    m_NewsItems[3].currency = "GBP";
    m_NewsItems[3].importance = 2;
    m_NewsItems[3].timestamp = TimeCurrent() - 14400;
    m_NewsItems[3].impact_score = -0.3;
    m_NewsItems[3].is_processed = true;
    
    m_NewsItems[4].title = "Unemployment Rate Drops to Decade Low";
    m_NewsItems[4].description = "US unemployment falls to 3.4%, lowest level in 10 years";
    m_NewsItems[4].category = "Employment";
    m_NewsItems[4].country = "US";
    m_NewsItems[4].currency = "USD";
    m_NewsItems[4].importance = 2;
    m_NewsItems[4].timestamp = TimeCurrent() - 18000;
    m_NewsItems[4].impact_score = 0.5;
    m_NewsItems[4].is_processed = true;
    
    //--- Fill remaining slots with lower impact news
    for(int i = 5; i < 10; i++)
    {
        m_NewsItems[i].title = "Market Update " + IntegerToString(i);
        m_NewsItems[i].description = "General market commentary and analysis";
        m_NewsItems[i].category = "Market Commentary";
        m_NewsItems[i].country = "Global";
        m_NewsItems[i].currency = "USD";
        m_NewsItems[i].importance = 1;
        m_NewsItems[i].timestamp = TimeCurrent() - (21600 + i * 3600);
        m_NewsItems[i].impact_score = (MathRand() % 200 - 100) / 1000.0; // Random between -0.1 and 0.1
        m_NewsItems[i].is_processed = true;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize sentiment keywords                                    |
//+------------------------------------------------------------------+
bool CNewsAnalyzer::InitializeKeywords()
{
    //--- Positive keywords
    ArrayResize(m_PositiveKeywords, 30);
    m_PositiveKeywords[0] = "growth"; m_PositiveKeywords[1] = "increase"; m_PositiveKeywords[2] = "rise";
    m_PositiveKeywords[3] = "bullish"; m_PositiveKeywords[4] = "positive"; m_PositiveKeywords[5] = "strong";
    m_PositiveKeywords[6] = "optimistic"; m_PositiveKeywords[7] = "boost"; m_PositiveKeywords[8] = "surge";
    m_PositiveKeywords[9] = "rally"; m_PositiveKeywords[10] = "recovery"; m_PositiveKeywords[11] = "expansion";
    m_PositiveKeywords[12] = "improvement"; m_PositiveKeywords[13] = "outperform"; m_PositiveKeywords[14] = "exceed";
    m_PositiveKeywords[15] = "beat"; m_PositiveKeywords[16] = "upward"; m_PositiveKeywords[17] = "gains";
    m_PositiveKeywords[18] = "advance"; m_PositiveKeywords[19] = "strengthen"; m_PositiveKeywords[20] = "support";
    m_PositiveKeywords[21] = "confidence"; m_PositiveKeywords[22] = "stable"; m_PositiveKeywords[23] = "solid";
    m_PositiveKeywords[24] = "robust"; m_PositiveKeywords[25] = "healthy"; m_PositiveKeywords[26] = "encouraging";
    m_PositiveKeywords[27] = "favorable"; m_PositiveKeywords[28] = "breakthrough"; m_PositiveKeywords[29] = "progress";
    
    //--- Negative keywords
    ArrayResize(m_NegativeKeywords, 30);
    m_NegativeKeywords[0] = "decline"; m_NegativeKeywords[1] = "decrease"; m_NegativeKeywords[2] = "fall";
    m_NegativeKeywords[3] = "bearish"; m_NegativeKeywords[4] = "negative"; m_NegativeKeywords[5] = "weak";
    m_NegativeKeywords[6] = "pessimistic"; m_NegativeKeywords[7] = "drop"; m_NegativeKeywords[8] = "crash";
    m_NegativeKeywords[9] = "sell-off"; m_NegativeKeywords[10] = "recession"; m_NegativeKeywords[11] = "contraction";
    m_NegativeKeywords[12] = "deterioration"; m_NegativeKeywords[13] = "underperform"; m_NegativeKeywords[14] = "miss";
    m_NegativeKeywords[15] = "below"; m_NegativeKeywords[16] = "downward"; m_NegativeKeywords[17] = "losses";
    m_NegativeKeywords[18] = "retreat"; m_NegativeKeywords[19] = "weaken"; m_NegativeKeywords[20] = "pressure";
    m_NegativeKeywords[21] = "concern"; m_NegativeKeywords[22] = "volatile"; m_NegativeKeywords[23] = "uncertainty";
    m_NegativeKeywords[24] = "fragile"; m_NegativeKeywords[25] = "troubled"; m_NegativeKeywords[26] = "worrying";
    m_NegativeKeywords[27] = "unfavorable"; m_NegativeKeywords[28] = "crisis"; m_NegativeKeywords[29] = "risk";
    
    return true;
}

//+------------------------------------------------------------------+
//| Analyze sentiment of text                                       |
//+------------------------------------------------------------------+
double CNewsAnalyzer::AnalyzeSentiment(string text)
{
    string clean_text = CleanNewsText(text);
    
    int positive_count = CountKeywordMatches(clean_text, m_PositiveKeywords);
    int negative_count = CountKeywordMatches(clean_text, m_NegativeKeywords);
    
    if(positive_count + negative_count == 0)
        return 0.0;
    
    double sentiment = (double)(positive_count - negative_count) / (positive_count + negative_count);
    
    //--- Apply text length normalization
    int text_length = StringLen(clean_text);
    double length_factor = MathMin(1.0, (double)text_length / 500.0);
    
    return sentiment * length_factor;
}

//+------------------------------------------------------------------+
//| Check if news is relevant for symbol                            |
//+------------------------------------------------------------------+
bool CNewsAnalyzer::IsRelevantForSymbol(SNewsItem &item, string symbol)
{
    string base_currency = StringSubstr(symbol, 0, 3);
    string quote_currency = StringSubstr(symbol, 3, 3);
    
    //--- Check if news currency matches symbol currencies
    if(item.currency == base_currency || item.currency == quote_currency)
        return true;
    
    //--- Check if news affects major currencies and symbol contains them
    if(item.importance >= 2 && (item.currency == "USD" || item.currency == "EUR" || item.currency == "GBP"))
    {
        if(StringFind(symbol, item.currency) >= 0)
            return true;
    }
    
    //--- Check for global impact news
    if(item.importance >= 3 && item.country == "US")
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Generate news summary                                            |
//+------------------------------------------------------------------+
string CNewsAnalyzer::GenerateSummary(SNewsItem &items[])
{
    if(ArraySize(items) == 0)
        return "No relevant news available";
    
    string summary = "Recent Analysis: ";
    int high_impact_count = 0;
    
    for(int i = 0; i < ArraySize(items) && i < 5; i++) // Limit to top 5 news items
    {
        if(items[i].importance >= 2)
        {
            if(high_impact_count > 0) summary += "; ";
            summary += items[i].title;
            high_impact_count++;
        }
    }
    
    if(high_impact_count == 0)
    {
        summary += "Low impact news detected. Market sentiment appears neutral.";
    }
    
    return StringSubstr(summary, 0, 200); // Limit summary length
}

//+------------------------------------------------------------------+
//| Get volatility forecast                                          |
//+------------------------------------------------------------------+
double CNewsAnalyzer::GetVolatilityForecast(SNewsItem &items[])
{
    double volatility = 0.0;
    
    for(int i = 0; i < ArraySize(items); i++)
    {
        volatility += (double)items[i].importance * MathAbs(items[i].impact_score);
    }
    
    return MathMin(1.0, volatility / 5.0); // Normalize to 0-1 range
}

//+------------------------------------------------------------------+
//| Clean news text for analysis                                    |
//+------------------------------------------------------------------+
string CNewsAnalyzer::CleanNewsText(string text)
{
    string result = text;
    StringToLower(result);
    
    //--- Remove special characters and numbers
    StringReplace(result, ".", " ");
    StringReplace(result, ",", " ");
    StringReplace(result, "!", " ");
    StringReplace(result, "?", " ");
    StringReplace(result, ":", " ");
    StringReplace(result, ";", " ");
    
    //--- Remove extra spaces
    while(StringFind(result, "  ") >= 0)
    {
        StringReplace(result, "  ", " ");
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Count keyword matches in text                                   |
//+------------------------------------------------------------------+
int CNewsAnalyzer::CountKeywordMatches(string text, string keywords[])
{
    int count = 0;
    
    for(int i = 0; i < ArraySize(keywords); i++)
    {
        if(StringFind(text, keywords[i]) >= 0)
            count++;
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Fetch news from Forex Factory                                   |
//+------------------------------------------------------------------+
bool CNewsAnalyzer::FetchFromForexFactory()
{
    //--- This is a placeholder for actual HTTP implementation
    //--- In a real implementation, you would use WebRequest or DLL calls
    Print("Fetching from Forex Factory (demo mode)");
    
    return CreateDemoNewsData(); // Use demo data for now
}

//+------------------------------------------------------------------+
//| Fetch news from API                                             |
//+------------------------------------------------------------------+
bool CNewsAnalyzer::FetchFromAPI()
{
    //--- This is a placeholder for actual API implementation
    Print("Fetching from API (demo mode)");
    
    return CreateDemoNewsData(); // Use demo data for now
}

//+------------------------------------------------------------------+
//| Extract currency from symbol                                    |
//+------------------------------------------------------------------+
string CNewsAnalyzer::ExtractCurrencyFromSymbol(string symbol)
{
    if(StringLen(symbol) >= 6)
        return StringSubstr(symbol, 0, 3);
    
    return "";
}

//+------------------------------------------------------------------+
//| Set news source                                                 |
//+------------------------------------------------------------------+
void CNewsAnalyzer::SetNewsSource(ENUM_NEWS_SOURCE source)
{
    m_NewsSource = source;
}

//+------------------------------------------------------------------+
//| Set analysis timeframe                                          |
//+------------------------------------------------------------------+
void CNewsAnalyzer::SetAnalysisTimeframe(int hours)
{
    m_AnalysisHours = MathMax(1, MathMin(168, hours)); // 1 hour to 1 week
}

//+------------------------------------------------------------------+
//| Set API key                                                     |
//+------------------------------------------------------------------+
void CNewsAnalyzer::SetAPIKey(string key)
{
    m_APIKey = key;
}