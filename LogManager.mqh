// LogManager.mqh

#ifndef __LOGMANAGER_MQH__
#define __LOGMANAGER_MQH__

#include "LogDefinitions.mqh"
#include "Logger.mqh"
#include "DataStructures.mqh"  // For AggregatedError
#include "Utils.mqh"           // For SanitizeForSQL and FormatErrorMessage functions

// Forward declaration of CDatabaseManager to avoid circular dependency
class CDatabaseManager;

// Declare the global database manager
extern CDatabaseManager dbManager;

class CLogManager
{
private:
    CLogger m_logger;
    bool m_enableDebugLogging;

    // Aggregated errors array
    AggregatedError m_aggregatedErrors[];

public:
    // Constructor
    CLogManager() {}

    // Init method
    void Init(LogLevelEnum logLevel = LOG_LEVEL_INFO,
              uint logCategories = LOG_CAT_ALL,
              bool enableConsoleLogging = true,
              bool enableDatabaseLogging = true,
              bool enableFileLogging = false,
              string logFilePath = "",
              int bufferFlushSize = 10,
              bool enableDebugLogging = false)
    {
        // Initialize m_logger
        m_logger.Init(logLevel,
                      logCategories,
                      enableConsoleLogging,
                      enableDatabaseLogging,
                      enableFileLogging,
                      logFilePath,
                      enableDebugLogging);

        m_logger.SetBufferFlushSize(bufferFlushSize);
        m_enableDebugLogging = enableDebugLogging;
    }

    // Destructor
    ~CLogManager()
    {
        // Flush logs and errors before destruction
        FlushAllLogs();
    }

    // Adjust logging parameters
    void SetLogLevel(LogLevelEnum logLevel)           { m_logger.SetLogLevel(logLevel); }
    void SetLogCategories(uint logCategories)         { m_logger.SetLogCategories(logCategories); }
    uint GetLogCategories()                           { return m_logger.GetLogCategories(); }
    void EnableConsoleLogging(bool enable)            { m_logger.EnableConsoleLogging(enable); }
    void EnableDatabaseLogging(bool enable)           { m_logger.EnableDatabaseLogging(enable); }
    void EnableFileLogging(bool enable)               { m_logger.EnableFileLogging(enable); }
    void SetLogFilePath(string logFilePath)           { m_logger.SetLogFilePath(logFilePath); }
    void SetBufferFlushSize(int size)                 { m_logger.SetBufferFlushSize(size); }

    // Flush all logs to database
    void FlushLogsToDatabase()                        { m_logger.FlushLogsToDatabase(); }

    // Flush all logs and aggregated errors
    void FlushAllLogs()
    {
        FlushAggregatedErrors();  // Now integrated within CLogManager
        m_logger.FlushAllLogs();
    }

    // Log a message
    void LogMessage(string message, LogLevelEnum messageLevel = LOG_LEVEL_INFO, uint category = LOG_CAT_OTHER)
    {
        if (ShouldLog(messageLevel, category))
            m_logger.LogMessage(message, messageLevel, category);
    }

    // Check if a message should be logged
    bool ShouldLog(LogLevelEnum messageLevel, uint category)
    {
        if (messageLevel == LOG_LEVEL_DEBUG && !m_enableDebugLogging)
            return false;

        return m_logger.ShouldLog(messageLevel, category);
    }

    // Aggregate an error
    void AggregateError(int errorCode, string errorMessage)
    {
        for (int i = 0; i < ArraySize(m_aggregatedErrors); i++)
        {
            if (m_aggregatedErrors[i].errorCode == errorCode && m_aggregatedErrors[i].errorMessage == errorMessage)
            {
                m_aggregatedErrors[i].count++;
                m_aggregatedErrors[i].lastOccurrence = TimeCurrent();
                return;
            }
        }

        AggregatedError newError;
        newError.errorCode = errorCode;
        newError.errorMessage = errorMessage;
        newError.count = 1;
        newError.firstOccurrence = TimeCurrent();
        newError.lastOccurrence = TimeCurrent();

        ArrayResize(m_aggregatedErrors, ArraySize(m_aggregatedErrors) + 1);
        m_aggregatedErrors[ArraySize(m_aggregatedErrors) - 1] = newError;
    }

    // Flush aggregated errors to the database
    void FlushAggregatedErrors()
    {
        for (int i = 0; i < ArraySize(m_aggregatedErrors); i++)
        {
            AggregatedError error = m_aggregatedErrors[i];

            // Prepare SQL insertion query
            string insertQuery = "INSERT INTO ErrorAggregations (ErrorCode, ErrorMessage, Count, FirstOccurrence, LastOccurrence) "
                                 "VALUES (" + IntegerToString(error.errorCode) + ", '" + SanitizeForSQL(error.errorMessage) + "', " +
                                 IntegerToString(error.count) + ", '" + TimeToString(error.firstOccurrence, TIME_DATE | TIME_SECONDS) + "', '" +
                                 TimeToString(error.lastOccurrence, TIME_DATE | TIME_SECONDS) + "') "
                                 "ON CONFLICT(ErrorCode, ErrorMessage) DO UPDATE SET "
                                 "Count = Count + " + IntegerToString(error.count) + ", "
                                 "LastOccurrence = '" + TimeToString(error.lastOccurrence, TIME_DATE | TIME_SECONDS) + "';";

            string errorMsg;
            if (!dbManager.ExecuteSQLQuery(insertQuery, errorMsg))
            {
                // Call LogMessage directly
                LogMessage("Failed to log aggregated error to database. Error: " + errorMsg, LOG_LEVEL_ERROR, LOG_CAT_DATABASE);
            }
        }

        ArrayResize(m_aggregatedErrors, 0);  // Clear aggregated errors after flushing
    }

    // LogFailedTrade Method
    void LogFailedTrade(string reason, double atrValue, string symbol, uint errorCode = 0, string errorDescription = "")
    {
        datetime currentTime = TimeCurrent();
        string date = TimeToString(currentTime, TIME_DATE);
        string time = TimeToString(currentTime, TIME_SECONDS | TIME_MINUTES);

        // Sanitize and handle single quotes in reason
        string sanitizedReason = SanitizeForSQL(reason);

        // Fetch or generate the error code and description
        if (errorCode == 0)
        {
            errorCode = GetLastError();
            errorDescription = ErrorDescription((int)errorCode);
            ResetLastError();
        }

        // Use FormatErrorMessage from Utils.mqh
        string fullReason = sanitizedReason + " - " + FormatErrorMessage(errorCode, errorDescription);

        // Prepare the SQL query
        string insertQuery = "INSERT INTO TradeLog (Date, Time, Symbol, Remarks, ATR) VALUES ("
                             "'" + date + "',"
                             "'" + time + "',"
                             "'" + symbol + "',"
                             "'" + SanitizeForSQL(fullReason) + "',"
                             + DoubleToString(atrValue, _Digits) + ");";

        // Execute the SQL query using dbManager
        string errorMsg;
        if (!dbManager.ExecuteSQLQuery(insertQuery, errorMsg))
        {
            // Call LogMessage directly
            LogMessage("Error inserting failed trade log to database: " + errorMsg, LOG_LEVEL_ERROR, LOG_CAT_DATABASE);
        }
        else
        {
            LogMessage("Failed trade logged to database successfully.", LOG_LEVEL_INFO, LOG_CAT_DATABASE);
        }

        // Aggregate the error
        AggregateError((int)errorCode, fullReason);
    }
};

#endif // __LOGMANAGER_MQH__
