   // Logger.mqh
   #ifndef __LOGGER_MQH__
   #define __LOGGER_MQH__
   
   #include "LogDefinitions.mqh"    // Include definitions for LogLevelEnum, etc.
   #include "DatabaseManager.mqh"   // Include CDatabaseManager for database interactions
   #include "LogFormatter.mqh"      // Include CLogFormatter for message formatting
   #include "Utils.mqh"             // Include utility functions if needed
   
   // Declare the global database manager
   extern CDatabaseManager dbManager;
   
   class CLogger
   {
   private:
       // Configuration parameters
       LogLevelEnum m_logLevel;
       uint         m_logCategories;
       bool         m_enableConsoleLogging;
       bool         m_enableDatabaseLogging;
       bool         m_enableFileLogging;
       string       m_logFilePath;
       bool         m_enableDebugLogging;
   
       // Internal variables
       CLogFormatter m_formatter;       // Formatter instance
       string        m_logBuffer[];     // Buffer for file and console logs
       string        m_dbLogBuffer[];   // Buffer for database logs
   
       // Buffer settings
       int           m_bufferFlushSize;
   
   public:
       // Constructor
       CLogger()
       {
           // Initialize default values
           m_logLevel              = LOG_LEVEL_INFO;
           m_logCategories         = LOG_CAT_ALL;
           m_enableConsoleLogging  = true;
           m_enableDatabaseLogging = true;
           m_enableFileLogging     = false;
           m_logFilePath           = "";
           m_bufferFlushSize       = 10; // Flush buffers after 10 messages
       }
   
       // Init method
       void Init(LogLevelEnum logLevel = LOG_LEVEL_INFO,
                 uint logCategories = LOG_CAT_ALL,
                 bool enableConsoleLogging = true,
                 bool enableDatabaseLogging = true,
                 bool enableFileLogging = false,
                 string logFilePath = "",
                 bool enableDebugLogging = false)
       {
           m_logLevel              = logLevel;
           m_logCategories         = logCategories;
           m_enableConsoleLogging  = enableConsoleLogging;
           m_enableDatabaseLogging = enableDatabaseLogging;
           m_enableFileLogging     = enableFileLogging;
           m_logFilePath           = logFilePath;
           m_enableDebugLogging    = enableDebugLogging;
       }
   
       // Destructor
       ~CLogger()
       {
           // Flush any remaining logs
           FlushLogsToFile();
           FlushLogsToDatabase();
       }
   
       // Getter for log categories
       uint GetLogCategories() const
       {
           return m_logCategories;
       }
   
       // Methods to adjust logging parameters
       void SetLogLevel(LogLevelEnum logLevel)          { m_logLevel = logLevel; }
       void SetLogCategories(uint logCategories)        { m_logCategories = logCategories; }
       void EnableConsoleLogging(bool enable)           { m_enableConsoleLogging = enable; }
       void EnableDatabaseLogging(bool enable)          { m_enableDatabaseLogging = enable; }
       void EnableFileLogging(bool enable)              { m_enableFileLogging = enable; }
       void SetLogFilePath(string logFilePath)          { m_logFilePath = logFilePath; }
       void SetBufferFlushSize(int size)                { m_bufferFlushSize = size; }
   
       // Method to log messages
       void LogMessage(string message, LogLevelEnum messageLevel = LOG_LEVEL_INFO, uint category = LOG_CAT_OTHER)
       {
           if (!ShouldLog(messageLevel, category))
               return;
   
           // Centralized log entry creation
           string formattedMessage = CreateFormattedMessage(message, messageLevel, category);
   
           // Buffering for console and file logs
           if (m_enableConsoleLogging || m_enableFileLogging)
           {
               ArrayResize(m_logBuffer, ArraySize(m_logBuffer) + 1);
               m_logBuffer[ArraySize(m_logBuffer) - 1] = formattedMessage;
   
               if (ArraySize(m_logBuffer) >= m_bufferFlushSize)
               {
                   FlushLogsToFile();
                   FlushLogsToConsole();
               }
           }
   
           // Buffering for database logs
           if (m_enableDatabaseLogging)
           {
               string dbLogEntry = CreateDatabaseLogEntry(message, messageLevel, category);
               ArrayResize(m_dbLogBuffer, ArraySize(m_dbLogBuffer) + 1);
               m_dbLogBuffer[ArraySize(m_dbLogBuffer) - 1] = dbLogEntry;
   
               if (ArraySize(m_dbLogBuffer) >= m_bufferFlushSize)
               {
                   FlushLogsToDatabase();
               }
           }
   
   #ifdef DEBUG
           // Immediate logging for debug messages
           if (messageLevel == LOG_LEVEL_DEBUG)
           {
               if (m_enableConsoleLogging)
                   Print(formattedMessage);
               if (m_enableFileLogging)
                   WriteLogToFile(formattedMessage);
           }
   #endif
       }
   
       // Method to flush logs to the database
       void FlushLogsToDatabase()
       {
           if (!m_enableDatabaseLogging || dbManager.GetDBHandle() == 0 || ArraySize(m_dbLogBuffer) == 0)
               return;
   
           string errorMsg;
   
           // Begin transaction
           if (!dbManager.ExecuteSQLQuery("BEGIN TRANSACTION;", errorMsg))
           {
               PrintFormat("Error starting transaction: %s", errorMsg);
               return;
           }
   
           // Write each log entry
           for (int i = 0; i < ArraySize(m_dbLogBuffer); i++)
           {
               string insertQuery = m_dbLogBuffer[i];
   
               if (!dbManager.ExecuteSQLQuery(insertQuery, errorMsg))
               {
                   PrintFormat("Error inserting log message to database: %s", errorMsg);
               }
           }
   
           // Commit transaction
           if (!dbManager.ExecuteSQLQuery("COMMIT;", errorMsg))
           {
               PrintFormat("Error committing transaction: %s", errorMsg);
           }
   
           // Clear the buffer after flushing
           ArrayResize(m_dbLogBuffer, 0);
       }
   
       // Method to flush logs to file
       void FlushLogsToFile()
       {
           if (!m_enableFileLogging || StringLen(m_logFilePath) == 0 || ArraySize(m_logBuffer) == 0)
               return;
   
           int fileHandle = FileOpen(m_logFilePath, FILE_WRITE | FILE_READ | FILE_TXT | FILE_COMMON);
           if (fileHandle != INVALID_HANDLE)
           {
               // Move to the end of the file
               FileSeek(fileHandle, 0, SEEK_END);
   
               // Write buffered messages
               for (int i = 0; i < ArraySize(m_logBuffer); i++)
               {
                   FileWriteString(fileHandle, m_logBuffer[i] + "\r\n");
               }
   
               FileClose(fileHandle);
           }
           else
           {
               Print("Failed to open log file for writing: " + m_logFilePath);
           }
   
           // Clear the buffer after flushing
           ArrayResize(m_logBuffer, 0);
       }
   
       // Method to flush logs to console
       void FlushLogsToConsole()
       {
           if (!m_enableConsoleLogging || ArraySize(m_logBuffer) == 0)
               return;
   
           for (int i = 0; i < ArraySize(m_logBuffer); i++)
           {
               Print(m_logBuffer[i]);
           }
   
           // Clear the buffer after flushing
           ArrayResize(m_logBuffer, 0);
       }
   
       // Method to force flush all logs
       void FlushAllLogs()
       {
           FlushLogsToConsole();
           FlushLogsToFile();
           FlushLogsToDatabase();
       }
   
       // Method to check if a message should be logged
       bool ShouldLog(LogLevelEnum messageLevel, uint category)
       {
           // Prevent logging debug-level messages unless explicitly enabled
           if (messageLevel == LOG_LEVEL_DEBUG && !m_enableDebugLogging)
               return false;
   
           // Disable all logging if the global log level is set to NONE
           if (m_logLevel == LOG_LEVEL_NONE)
               return false;
   
           // Do nothing if the category is set to 0
           if (category == 0)
               return false;
   
           // Special handling: When log level is INFO, only log INFO messages
           if (m_logLevel == LOG_LEVEL_INFO && messageLevel != LOG_LEVEL_INFO)
               return false;
   
           // For other log levels, allow all logs with severity <= the selected level
           if (messageLevel > m_logLevel)
               return false;
   
           // Ensure the log category matches the selected categories
           if ((m_logCategories & category) == 0)
               return false;
   
           return true; // Log if all conditions pass
       }
   
   private:
       // Helper function to create formatted message
       string CreateFormattedMessage(string message, LogLevelEnum messageLevel, uint category)
       {
           bool detailedFormat = true;
   
   #ifdef DEBUG
           // Use detailed format in debug mode
           detailedFormat = true;
   #else
           // Use concise format in release mode
           detailedFormat = false;
   #endif
   
           return m_formatter.FormatMessage(message, messageLevel, category, detailedFormat);
       }
   
       // Helper function to create database log entry
       string CreateDatabaseLogEntry(string message, LogLevelEnum messageLevel, uint category)
       {
           // Sanitize the log message to escape single quotes
           string sanitizedMessage = message;
           StringReplace(sanitizedMessage, "'", "''");
   
           datetime currentTime = TimeCurrent();
           string date = TimeToString(currentTime, TIME_DATE);
           string time = TimeToString(currentTime, TIME_SECONDS | TIME_MINUTES);
   
           string logLevelStr = m_formatter.GetLogLevelString(messageLevel);
           string categoryStr = m_formatter.GetCategoryString(category);
   
           // Build the INSERT query
           string insertQuery = "INSERT INTO LogEntries (Date, Time, LogLevel, Category, Message) VALUES ("
                                "'" + date + "',"
                                "'" + time + "',"
                                "'" + logLevelStr + "',"
                                "'" + categoryStr + "',"
                                "'" + sanitizedMessage + "');";
   
           return insertQuery;
       }
   
       // Method to write log directly to file
       void WriteLogToFile(string formattedMessage)
       {
           int fileHandle = FileOpen(m_logFilePath, FILE_WRITE | FILE_READ | FILE_TXT | FILE_COMMON);
           if (fileHandle != INVALID_HANDLE)
           {
               // Move to the end of the file
               FileSeek(fileHandle, 0, SEEK_END);
   
               // Write the message
               FileWriteString(fileHandle, formattedMessage + "\r\n");
   
               FileClose(fileHandle);
           }
           else
           {
               Print("Failed to open log file for writing: " + m_logFilePath);
           }
       }
   
       // Utility functions to convert log level and category to strings
       string LogLevelToString(LogLevelEnum level) { return m_formatter.GetLogLevelString(level); }
       string LogCategoryToString(uint category)   { return m_formatter.GetCategoryString(category); }
   };
   
   #endif // __LOGGER_MQH__
