// LogManager.mqh

#ifndef __LOGMANAGER_MQH__
#define __LOGMANAGER_MQH__

#include "LogDefinitions.mqh"  // Include first to define enums used in other headers
#include "Logger.mqh"          // Include after LogDefinitions.mqh

// Declare the global database manager
extern CDatabaseManager dbManager;

class CLogManager
{
private:
    CLogger m_logger;
    bool m_enableDebugLogging; // Add this line

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
             bool enableDebugLogging = false) // Add this parameter
   {
       // Initialize m_logger
       m_logger.Init(logLevel,
                     logCategories,
                     enableConsoleLogging,
                     enableDatabaseLogging,
                     enableFileLogging,
                     logFilePath,
                     enableDebugLogging); // Pass it to m_logger
   
       m_logger.SetBufferFlushSize(bufferFlushSize);
       m_enableDebugLogging = enableDebugLogging; // Store the value
   }

    // Destructor
    ~CLogManager()
    {
        // Ensure all logs are flushed
        m_logger.FlushAllLogs();
    }

    // Methods to adjust logging parameters
    void SetLogLevel(LogLevelEnum logLevel)           { m_logger.SetLogLevel(logLevel); }
    void SetLogCategories(uint logCategories)         { m_logger.SetLogCategories(logCategories); }
    void EnableConsoleLogging(bool enable)            { m_logger.EnableConsoleLogging(enable); }
    void EnableDatabaseLogging(bool enable)           { m_logger.EnableDatabaseLogging(enable); }
    void EnableFileLogging(bool enable)               { m_logger.EnableFileLogging(enable); }
    void SetLogFilePath(string logFilePath)           { m_logger.SetLogFilePath(logFilePath); }
    void SetBufferFlushSize(int size)                 { m_logger.SetBufferFlushSize(size); }

    // Methods to flush logs
    void FlushLogsToDatabase()                        { m_logger.FlushLogsToDatabase(); }
    void FlushAllLogs()                               { m_logger.FlushAllLogs(); }

    // Method to log messages
    void LogMessage(string message, LogLevelEnum messageLevel = LOG_LEVEL_INFO, uint category = LOG_CAT_OTHER)
    {
        if (ShouldLog(messageLevel, category))
            m_logger.LogMessage(message, messageLevel, category);
    }

    // Method to check if a message should be logged
   bool ShouldLog(LogLevelEnum messageLevel, uint category)
   {
       // Use the member variable instead of the extern variable
       if (messageLevel == LOG_LEVEL_DEBUG && !m_enableDebugLogging)
           return false;
   
       return m_logger.ShouldLog(messageLevel, category);
   }
};

#endif // __LOGMANAGER_MQH__
