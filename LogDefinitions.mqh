#ifndef __LOGDEFINITIONS_MQH__
#define __LOGDEFINITIONS_MQH__

// Enum for log levels
enum LogLevelEnum
{
    LOG_LEVEL_NONE   = 0,
    LOG_LEVEL_ERROR  = 1,
    LOG_LEVEL_WARNING= 2,
    LOG_LEVEL_INFO   = 3,
    LOG_LEVEL_DEBUG  = 4
};

// Enum for log categories
enum LogCategoryEnum {
    LOG_CAT_NONE            = 0x0000,
    LOG_CAT_ATR             = 0x0001,
    LOG_CAT_TRADE_EXECUTION = 0x0002,
    LOG_CAT_SLTP_VALUES     = 0x0004,
    LOG_CAT_RISK_MANAGEMENT = 0x0008,
    LOG_CAT_ERRORS          = 0x0010,
    LOG_CAT_OTHER           = 0x0020,
    LOG_CAT_ALL             = 0xFFFF
};

// Struct to store log entries
struct LogEntry {
    string date;
    string time;
    string logLevel;
    string category;
    string message;
};

#endif // __LOGDEFINITIONS_MQH__
