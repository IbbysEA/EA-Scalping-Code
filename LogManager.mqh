// LogManager.mqh
#ifndef __LOGMANAGER_MQH__
#define __LOGMANAGER_MQH__

#include "LogDefinitions.mqh"  // Include first to define enums used in other headers
#include "DatabaseManager.mqh" // Ensure CDatabaseManager is defined before use
#include "Logger.mqh"          // Include after DatabaseManager.mqh
#include "Utils.mqh"           // Include if needed

// Declare the database manager as extern if it's used in other files
extern CDatabaseManager dbManager; // Ensure CDatabaseManager is defined before this line

class CLogManager
{
private:
   CLogger m_logger;

   // Configuration parameters
   LogLevelEnum m_logLevel;
   uint         m_logCategories;
   bool         m_enableConsoleLogging;
   bool         m_enableDatabaseLogging;
   bool         m_enableFileLogging;
   string       m_logFilePath;

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
      m_logLevel              = logLevel;
      m_logCategories         = logCategories;
      m_enableConsoleLogging  = enableConsoleLogging;
      m_enableDatabaseLogging = enableDatabaseLogging;
      m_enableFileLogging     = enableFileLogging;
      m_logFilePath           = logFilePath;

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
      if (!ShouldLog(messageLevel, category))
         return;

      m_logger.LogMessage(message, messageLevel, category);
   }

   // Method to check if a message should be logged
   bool ShouldLog(LogLevelEnum messageLevel, uint category)
   {
      if (m_logLevel == LOG_LEVEL_NONE)
         return false;
      if (messageLevel > m_logLevel)
         return false;
      if ((m_logCategories & category) == 0)
         return false;
      return true;
   }

   // Method to check if a log level is enabled
   bool IsLogLevelEnabled(LogLevelEnum messageLevel)
   {
      return messageLevel <= m_logLevel;
   }

   // Method to check if a category is enabled
   bool IsCategoryEnabled(uint category)
   {
      return (m_logCategories & category) != 0;
   }
};

#endif // __LOGMANAGER_MQH__