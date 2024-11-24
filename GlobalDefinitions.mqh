// GlobalDefinitions.mqh

#ifndef __GLOBALDEFINITIONS_MQH__
#define __GLOBALDEFINITIONS_MQH__

// Market condition constants
#define MARKET_CONDITION_UNKNOWN        0
#define MARKET_CONDITION_CONSOLIDATING  1
#define MARKET_CONDITION_TRENDING       2

#include "LogDefinitions.mqh"
#include "LogHelper.mqh"

// LOG_MESSAGE macro using LazyLogMessage function
#define LOG_MESSAGE(level, category, message) \
    do { LazyLogMessage(level, category, message); } while (0)

// Macro for logging arrays
#define LOG_ARRAY(level, category, array) \
    LOG_MESSAGE(level, category, BuildArrayLogMessage(array))

// Macro for multi-line messages
#define LOG_MULTILINE(level, category, header, footer, body) \
    LOG_MESSAGE(level, category, BuildMultiLineLogMessage(header, footer, body))

#endif // __GLOBALDEFINITIONS_MQH__
