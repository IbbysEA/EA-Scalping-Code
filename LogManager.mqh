// LogManager.mqh
#ifndef __LOGMANAGER_MQH__
#define __LOGMANAGER_MQH__

#include "Logger.mqh"
#include "LogDefinitions.mqh"
#include "DatabaseManager.mqh"

// Declare the database manager as extern if it's used in other files
extern CDatabaseManager dbManager;

class CLogManager {
private:
    CLogger m_logger;

    // Configuration parameters
    LogLevelEnum m_logLevel;
    uint m_logCategories;
    bool m_enableConsoleLogging;
    bool m_enableDatabaseLogging;
    bool m_enableFileLogging;
    string m_logFilePath;

public:
    // Default Constructor
    CLogManager() {}

    // Init method
    void Init(LogLevelEnum logLevel = LOG_LEVEL_INFO,
              uint logCategories = LOG_CAT_ALL,
              bool enableConsoleLogging = true,
              bool enableDatabaseLogging = true,
              bool enableFileLogging = false,
              string logFilePath = "")
    {
        m_logLevel = logLevel;
        m_logCategories = logCategories;
        m_enableConsoleLogging = enableConsoleLogging;
        m_enableDatabaseLogging = enableDatabaseLogging;
        m_enableFileLogging = enableFileLogging;
        m_logFilePath = logFilePath;

        // Initialize m_logger
        m_logger.Init(logLevel, logCategories, enableConsoleLogging, enableDatabaseLogging, enableFileLogging, logFilePath);
    }

    // Destructor
    ~CLogManager()
    {
        // No dynamic memory allocation, so nothing to do
    }

    // Methods to adjust logging parameters
    void SetLogLevel(LogLevelEnum logLevel)
    {
        m_logLevel = logLevel;
        m_logger.SetLogLevel(logLevel);
    }

    void SetLogCategories(uint logCategories)
    {
        m_logCategories = logCategories;
        m_logger.SetLogCategories(logCategories);
    }

    void EnableConsoleLogging(bool enable)
    {
        m_enableConsoleLogging = enable;
        m_logger.EnableConsoleLogging(enable);
    }

    void EnableDatabaseLogging(bool enable)
    {
        m_enableDatabaseLogging = enable;
        m_logger.EnableDatabaseLogging(enable);
    }

    void EnableFileLogging(bool enable)
    {
        m_enableFileLogging = enable;
        m_logger.EnableFileLogging(enable);
    }

    void SetLogFilePath(string logFilePath)
    {
        m_logFilePath = logFilePath;
        m_logger.SetLogFilePath(logFilePath);
    }

    // Methods to flush logs
    void FlushLogsToDatabase()
    {
        m_logger.FlushLogsToDatabase();
    }

    void FlushLogsToFile()
    {
        m_logger.FlushLogsToFile();
    }

    // Method to log messages
    void LogMessage(string message, LogLevelEnum messageLevel = LOG_LEVEL_INFO, uint category = LOG_CAT_OTHER)
    {
        m_logger.LogMessage(message, messageLevel, category);
    }
};

#endif // __LOGMANAGER_MQH__
