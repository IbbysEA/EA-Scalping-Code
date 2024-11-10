// GlobalDefinitions.mqh
#ifndef __GLOBALDEFINITIONS_MQH__
#define __GLOBALDEFINITIONS_MQH__

#include "LogDefinitions.mqh"  // Include LogDefinitions here

// Define the LOG_MESSAGE macro
#define LOG_MESSAGE(level, category, message_expr) \
   if (logManager.ShouldLog(level, category)) { \
      string message = message_expr; \
      logManager.LogMessage(message, level, category); \
   }

#endif // __GLOBALDEFINITIONS_MQH__
