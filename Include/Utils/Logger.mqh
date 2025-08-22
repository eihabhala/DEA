//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                                 Copyright 2024, AI Trading Team |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AI Trading Team"
#property link      "https://www.mql5.com"

//--- Log levels
enum ENUM_LOG_LEVEL
{
    LOG_LEVEL_DEBUG = 0,
    LOG_LEVEL_INFO = 1,
    LOG_LEVEL_WARNING = 2,
    LOG_LEVEL_ERROR = 3
};

//+------------------------------------------------------------------+
//| Logger Class                                                     |
//+------------------------------------------------------------------+
class CLogger
{
private:
    string              m_LogFileName;
    ENUM_LOG_LEVEL      m_LogLevel;
    bool                m_IsInitialized;
    bool                m_WriteToFile;
    bool                m_WriteToTerminal;
    
public:
                        CLogger();
                       ~CLogger();
    
    bool                Initialize(string filename = "AI_Trading_Log");
    void                Deinitialize();
    
    //--- Logging methods
    void                Debug(string message);
    void                Info(string message);
    void                Warning(string message);
    void                Error(string message);
    
    //--- Configuration
    void                SetLogLevel(ENUM_LOG_LEVEL level);
    void                SetWriteToFile(bool enable);
    void                SetWriteToTerminal(bool enable);
    
private:
    void                WriteLog(ENUM_LOG_LEVEL level, string message);
    string              FormatLogMessage(ENUM_LOG_LEVEL level, string message);
    string              GetLogLevelString(ENUM_LOG_LEVEL level);
    string              GetTimestamp();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogger::CLogger()
{
    m_IsInitialized = false;
    m_LogLevel = LOG_LEVEL_INFO;
    m_WriteToFile = true;
    m_WriteToTerminal = true;
    m_LogFileName = "";
}

//+------------------------------------------------------------------+
//| Initialize logger                                               |
//+------------------------------------------------------------------+
bool CLogger::Initialize(string filename = "AI_Trading_Log")
{
    m_LogFileName = filename + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
    m_IsInitialized = true;
    
    Info("Logger initialized - File: " + m_LogFileName);
    return true;
}

//+------------------------------------------------------------------+
//| Debug log                                                       |
//+------------------------------------------------------------------+
void CLogger::Debug(string message)
{
    WriteLog(LOG_LEVEL_DEBUG, message);
}

//+------------------------------------------------------------------+
//| Info log                                                        |
//+------------------------------------------------------------------+
void CLogger::Info(string message)
{
    WriteLog(LOG_LEVEL_INFO, message);
}

//+------------------------------------------------------------------+
//| Warning log                                                     |
//+------------------------------------------------------------------+
void CLogger::Warning(string message)
{
    WriteLog(LOG_LEVEL_WARNING, message);
}

//+------------------------------------------------------------------+
//| Error log                                                       |
//+------------------------------------------------------------------+
void CLogger::Error(string message)
{
    WriteLog(LOG_LEVEL_ERROR, message);
}

//+------------------------------------------------------------------+
//| Write log entry                                                 |
//+------------------------------------------------------------------+
void CLogger::WriteLog(ENUM_LOG_LEVEL level, string message)
{
    if(!m_IsInitialized || level < m_LogLevel) return;
    
    string formatted_message = FormatLogMessage(level, message);
    
    //--- Write to terminal
    if(m_WriteToTerminal)
    {
        Print(formatted_message);
    }
    
    //--- Write to file
    if(m_WriteToFile && m_LogFileName != "")
    {
        int file_handle = FileOpen(m_LogFileName, FILE_WRITE | FILE_TXT | FILE_ANSI, '\t');
        if(file_handle != INVALID_HANDLE)
        {
            FileSeek(file_handle, 0, SEEK_END);
            FileWriteString(file_handle, formatted_message + "\n");
            FileClose(file_handle);
        }
    }
}

//+------------------------------------------------------------------+
//| Format log message                                              |
//+------------------------------------------------------------------+
string CLogger::FormatLogMessage(ENUM_LOG_LEVEL level, string message)
{
    return GetTimestamp() + " [" + GetLogLevelString(level) + "] " + message;
}

//+------------------------------------------------------------------+
//| Get log level string                                            |
//+------------------------------------------------------------------+
string CLogger::GetLogLevelString(ENUM_LOG_LEVEL level)
{
    switch(level)
    {
        case LOG_LEVEL_DEBUG: return "DEBUG";
        case LOG_LEVEL_INFO: return "INFO";
        case LOG_LEVEL_WARNING: return "WARN";
        case LOG_LEVEL_ERROR: return "ERROR";
        default: return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Get timestamp                                                   |
//+------------------------------------------------------------------+
string CLogger::GetTimestamp()
{
    return TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Set log level                                                   |
//+------------------------------------------------------------------+
void CLogger::SetLogLevel(ENUM_LOG_LEVEL level)
{
    m_LogLevel = level;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogger::~CLogger()
{
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Deinitialize                                                     |
//+------------------------------------------------------------------+
void CLogger::Deinitialize()
{
    if(m_IsInitialized)
    {
        Info("Logger shutting down");
        m_IsInitialized = false;
    }
}