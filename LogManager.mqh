// LogManager.mqh

#ifndef __LOGMANAGER_MQH__
#define __LOGMANAGER_MQH__

#include "LogDefinitions.mqh"
#include "Logger.mqh"
#include "DataStructures.mqh"

// Declare the global database manager
extern CDatabaseManager dbManager;

class CLogManager
{
private:
    CLogger m_logger;
    bool m_enableDebugLogging;

    // Array to store aggregated errors
    AggregatedError m_errorAggregations[];

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
        // Flush aggregated errors before destruction
        FlushAggregatedErrors();
        m_logger.FlushAllLogs();  // Ensure all logs are flushed
    }

    // Adjust logging parameters
    void SetLogLevel(LogLevelEnum logLevel)           { m_logger.SetLogLevel(logLevel); }
    void SetLogCategories(uint logCategories)         { m_logger.SetLogCategories(logCategories); }
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
        FlushAggregatedErrors();
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

    // Aggregate errors by error code and message
    void AggregateError(int errorCode, string errorMessage)
    {
        for (int i = 0; i < ArraySize(m_errorAggregations); i++)
        {
            if (m_errorAggregations[i].errorCode == errorCode && m_errorAggregations[i].errorMessage == errorMessage)
            {
                m_errorAggregations[i].count++;
                m_errorAggregations[i].lastOccurrence = TimeCurrent();
                return;
            }
        }

        AggregatedError newError;
        newError.errorCode = errorCode;
        newError.errorMessage = errorMessage;
        newError.count = 1;
        newError.firstOccurrence = TimeCurrent();
        newError.lastOccurrence = TimeCurrent();

        ArrayResize(m_errorAggregations, ArraySize(m_errorAggregations) + 1);
        m_errorAggregations[ArraySize(m_errorAggregations) - 1] = newError;
    }

    // Flush aggregated errors to database
    void FlushAggregatedErrors()
    {
        for (int i = 0; i < ArraySize(m_errorAggregations); i++)
        {
            AggregatedError error = m_errorAggregations[i];

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
                PrintFormat("Failed to log aggregated error to database. Error: %s", errorMsg);
            }
        }

        ArrayResize(m_errorAggregations, 0); // Clear aggregated errors after flushing
    }
};

#endif // __LOGMANAGER_MQH__
