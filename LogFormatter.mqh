// LogFormatter.mqh

#ifndef __LOGFORMATTER_MQH__
#define __LOGFORMATTER_MQH__

#include "LogDefinitions.mqh"  // For LogLevelEnum and log categories

class CLogFormatter
{
public:
    // Constructor
    CLogFormatter() {}

    // Methods
    string FormatMessage(const string &message, LogLevelEnum messageLevel, uint category, bool detailed = true);
    string GetLogLevelString(LogLevelEnum logLevel);
    string GetCategoryString(uint category);
};

string CLogFormatter::FormatMessage(const string &message, LogLevelEnum messageLevel, uint category, bool detailed)
{
    string levelLabel = GetLogLevelString(messageLevel);
    string categoryStr = GetCategoryString(category);
    datetime currentTime = TimeCurrent();
    string date = TimeToString(currentTime, TIME_DATE);
    string time = TimeToString(currentTime, TIME_SECONDS | TIME_MINUTES);

    string formattedMessage;
    if (detailed)
    {
        formattedMessage = "[" + date + " " + time + "] [" + levelLabel + "] [" + categoryStr + "] " + message;
    }
    else
    {
        formattedMessage = "[" + levelLabel + "] " + message;
    }
    return formattedMessage;
}

string CLogFormatter::GetLogLevelString(LogLevelEnum logLevel)
{
    switch (logLevel)
    {
        case LOG_LEVEL_ERROR:   return "ERROR";
        case LOG_LEVEL_WARNING: return "WARNING";
        case LOG_LEVEL_INFO:    return "INFO";
        case LOG_LEVEL_DEBUG:   return "DEBUG";
        default:                return "UNKNOWN";
    }
}

string CLogFormatter::GetCategoryString(uint category)
{
    string categories = "";

    if ((category & LOG_CAT_TRADE_EXECUTION) != 0)   categories += "TradeExecution|";
    if ((category & LOG_CAT_AGGREGATED_ERRORS) != 0) categories += "AggregatedErrors|";
    if ((category & LOG_CAT_INITIALIZATION) != 0)    categories += "Initialization|";
    if ((category & LOG_CAT_DEINITIALIZATION) != 0)  categories += "Deinitialization|";
    if ((category & LOG_CAT_TRADE_MANAGEMENT) != 0)  categories += "TradeManagement|";
    if ((category & LOG_CAT_TRADE_LIMIT) != 0)       categories += "TradeLimit|";
    if ((category & LOG_CAT_COOLDOWN) != 0)          categories += "Cooldown|";
    if ((category & LOG_CAT_SLTP_VALUES) != 0)       categories += "SLTPValues|";
    if ((category & LOG_CAT_RISK_MANAGEMENT) != 0)   categories += "RiskManagement|";
    if ((category & LOG_CAT_ATR) != 0)               categories += "ATR|";
    if ((category & LOG_CAT_VOLUME) != 0)            categories += "Volume|";
    if ((category & LOG_CAT_INDICATORS) != 0)        categories += "Indicators|";
    if ((category & LOG_CAT_OTHER) != 0)             categories += "Other|";
    if ((category & LOG_CAT_PROFILING) != 0)         categories += "Profiling|";
    if ((category & LOG_CAT_PERFORMANCE) != 0)       categories += "Performance|";
    if ((category & LOG_CAT_DATABASE) != 0)         categories += "Database|";
    if ((category & LOG_CAT_DEV_STAGE) != 0)         categories += "DevStage|";
    
    // Remove the trailing '|'
    if (StringLen(categories) > 0)
        categories = StringSubstr(categories, 0, StringLen(categories) - 1);
    else
        categories = "None";

    return categories;
}

#endif // __LOGFORMATTER_MQH__
