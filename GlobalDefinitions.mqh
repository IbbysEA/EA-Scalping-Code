// GlobalDefinitions.mqh

#ifndef __GLOBALDEFINITIONS_MQH__
#define __GLOBALDEFINITIONS_MQH__

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
