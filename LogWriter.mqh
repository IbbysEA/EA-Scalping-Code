// LogWriter.mqh
#ifndef __LOGWRITER_MQH__
#define __LOGWRITER_MQH__

#include "LogDefinitions.mqh"
#include "DatabaseManager.mqh"
#include "LogFormatter.mqh"
#include "Utils.mqh"

class CLogWriter {
private:
    bool m_enableConsoleLogging;
    bool m_enableDatabaseLogging;
    bool m_enableFileLogging;
    CDatabaseManager *m_dbManager;
    string m_logFilePath;
    LogEntry m_logEntries[];

public:
    // Constructor
    CLogWriter(bool enableConsoleLogging,
               bool enableDatabaseLogging,
               bool enableFileLogging,
               CDatabaseManager *dbManagerParam = NULL,
               string logFilePath = "");

    // Copy constructor
    CLogWriter(const CLogWriter &other);

    // Destructor
    ~CLogWriter();

    // Methods
    void WriteLog(string formattedMessage, string message, LogLevelEnum messageLevel, uint category);
    void FlushLogsToDatabase();
    void FlushLogsToFile();

    // Methods to adjust logging parameters
    void EnableConsoleLogging(bool enable);
    void EnableDatabaseLogging(bool enable);
    void EnableFileLogging(bool enable);
    void SetLogFilePath(string logFilePath);
};

// Implementation of CLogWriter methods

// Constructor
CLogWriter::CLogWriter(bool enableConsoleLogging,
                       bool enableDatabaseLogging,
                       bool enableFileLogging,
                       CDatabaseManager *dbManagerParam,
                       string logFilePath) {
    m_enableConsoleLogging = enableConsoleLogging;
    m_enableDatabaseLogging = enableDatabaseLogging;
    m_enableFileLogging = enableFileLogging;
    m_dbManager = dbManagerParam;
    m_logFilePath = logFilePath;
}

// Copy constructor
CLogWriter::CLogWriter(const CLogWriter &other) {
    m_enableConsoleLogging = other.m_enableConsoleLogging;
    m_enableDatabaseLogging = other.m_enableDatabaseLogging;
    m_enableFileLogging = other.m_enableFileLogging;
    m_dbManager = other.m_dbManager; // Shallow copy of pointer
    m_logFilePath = other.m_logFilePath;

    // Copy the log entries array
    int size = ArraySize(other.m_logEntries);
    ArrayResize(m_logEntries, size);
    for (int i = 0; i < size; i++) {
        m_logEntries[i] = other.m_logEntries[i];
    }
}

// Destructor
CLogWriter::~CLogWriter() {
    // No dynamic memory allocation, so nothing to do
}

void CLogWriter::WriteLog(string formattedMessage, string message, LogLevelEnum messageLevel, uint category) {
    // Log to console
    if (m_enableConsoleLogging) {
        Print(formattedMessage);
    }

    // Log to database
    if (m_enableDatabaseLogging && m_dbManager != NULL && m_dbManager.GetDBHandle() != 0) {
        // Sanitize message to remove special symbols
        string sanitizedMessage = SanitizeForSQL(message);

        // Get current date and time
        string date = TimeToString(TimeCurrent(), TIME_DATE);
        string time = TimeToString(TimeCurrent(), TIME_SECONDS | TIME_MINUTES);

        // Prepare log level and category strings
        CLogFormatter formatter;
        string logLevelStr = formatter.GetLogLevelString(messageLevel);
        string categoryStr = formatter.GetCategoryString(category);

        // Create a new LogEntry
        LogEntry entry;
        entry.date = date;
        entry.time = time;
        entry.logLevel = logLevelStr;
        entry.category = categoryStr;
        entry.message = sanitizedMessage;

        // Add to the array
        ArrayResize(m_logEntries, ArraySize(m_logEntries) + 1);
        m_logEntries[ArraySize(m_logEntries) - 1] = entry;
    }

    // Log to file
    if (m_enableFileLogging && StringLen(m_logFilePath) > 0) {
        int fileHandle = FileOpen(m_logFilePath, FILE_WRITE | FILE_READ | FILE_TXT | FILE_COMMON);
        if (fileHandle != INVALID_HANDLE) {
            // Move to the end of the file
            FileSeek(fileHandle, 0, SEEK_END);
            // Write the formatted message
            FileWriteString(fileHandle, formattedMessage + "\r\n");
            FileClose(fileHandle);
        } else {
            Print("Failed to open log file for writing: " + m_logFilePath);
        }
    }
}

void CLogWriter::FlushLogsToDatabase() {
    if (!m_enableDatabaseLogging || m_dbManager == NULL || m_dbManager.GetDBHandle() == 0)
        return;

    string errorString;

    // Begin transaction
    if (!m_dbManager.ExecuteSQLQuery("BEGIN TRANSACTION;", errorString)) {
        PrintFormat("Error starting transaction: %s", errorString);
        return;
    }

    // Write each log entry
    for (int i = 0; i < ArraySize(m_logEntries); i++) {
        LogEntry entry = m_logEntries[i];

        // Construct SQL query
        string insertLogQuery = StringFormat(
            "INSERT INTO LogEntries (Date, Time, LogLevel, Category, Message) VALUES ('%s', '%s', '%s', '%s', '%s');",
            entry.date, entry.time, entry.logLevel, entry.category, entry.message
        );

        // Execute SQL query
        if (!m_dbManager.ExecuteSQLQuery(insertLogQuery, errorString)) {
            PrintFormat("Error executing query: %s", errorString);
            // Optionally, handle the error (e.g., retry, log to file, etc.)
        }
    }

    // Commit transaction
    if (!m_dbManager.ExecuteSQLQuery("COMMIT;", errorString)) {
        PrintFormat("Error committing transaction: %s", errorString);
    }

    // Clear the array
    ArrayResize(m_logEntries, 0);
}

// Methods to adjust logging parameters
void CLogWriter::EnableConsoleLogging(bool enable) {
    m_enableConsoleLogging = enable;
}

void CLogWriter::EnableDatabaseLogging(bool enable) {
    m_enableDatabaseLogging = enable;
}

void CLogWriter::EnableFileLogging(bool enable) {
    m_enableFileLogging = enable;
}

void CLogWriter::SetLogFilePath(string logFilePath) {
    m_logFilePath = logFilePath;
}

#endif // __LOGWRITER_MQH__