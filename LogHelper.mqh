// LogHelper.mqh

#ifndef __LOGHELPER_MQH__
#define __LOGHELPER_MQH__

#include "LogDefinitions.mqh"
#include "LogManager.mqh"  // Ensure CLogManager is defined
#include "DataStructures.mqh"

// Declare extern logManager after CLogManager is defined
extern CLogManager logManager;

// Helper function to build array log messages
string BuildArrayLogMessage(const double &array[])
{
    string message = "";
    for (int i = 0; i < ArraySize(array); i++)
        message += "Value[" + IntegerToString(i) + "] = " + DoubleToString(array[i], 2) + "; ";
    return message;
}

// Helper function for multi-line log messages
string BuildMultiLineLogMessage(const string &header, const string &footer, const string &body)
{
    return header + "\n" + body + "\n" + footer;
}

// Centralized function to check if a category is enabled
bool IsCategoryEnabled(uint category)
{
    return (logManager.GetLogCategories() & category) != 0;
}

// Lazy evaluation wrapper for logging
void LazyLogMessage(LogLevelEnum level, uint category, string message)
{
    if (logManager.ShouldLog(level, category) && IsCategoryEnabled(category))
        logManager.LogMessage(message, level, category);
}

#endif // __LOGHELPER_MQH__
