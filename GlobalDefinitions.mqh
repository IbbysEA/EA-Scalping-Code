// GlobalDefinitions.mqh

#ifndef __GLOBALDEFINITIONS_MQH__
#define __GLOBALDEFINITIONS_MQH__

// Macro to simplify logging calls
#define LOG_MESSAGE(level, category, message) \
    do { \
        if (logManager.ShouldLog(level, category)) \
            logManager.LogMessage(message, level, category); \
    } while(0)

#endif // __GLOBALDEFINITIONS_MQH__
