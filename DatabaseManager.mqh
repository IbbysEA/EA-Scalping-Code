// DatabaseManager.mqh
#ifndef __DATABASEMANAGER_MQH__
#define __DATABASEMANAGER_MQH__

#include "DatabaseImports.mqh"

class CDatabaseManager
{
private:
    ulong m_dbHandle;
    string m_dbPath;

public:
    // Constructor
    CDatabaseManager(string dbPathParam)
    {
        m_dbPath = dbPathParam;
        m_dbHandle = 0; // Initialize dbHandle to 0
    }

    // Destructor
    ~CDatabaseManager()
    {
        CloseDatabaseConnection();
    }

    // Open database connection
    bool OpenDatabaseConnection()
    {
        char errorMsg[256];
        // Convert m_dbPath to a null-terminated char array
        char dbPathCharArray[512];
        StringToCharArray(m_dbPath, dbPathCharArray, 0, StringLen(m_dbPath) + 1);

        m_dbHandle = OpenDatabase(dbPathCharArray, errorMsg, sizeof(errorMsg));
        if (m_dbHandle == 0)
        {
            PrintFormat("Failed to open database. Error: %s", CharArrayToString(errorMsg));
            return false;
        }
        return true;
    }

    // Close database connection
    void CloseDatabaseConnection()
    {
        if (m_dbHandle != 0)
        {
            CloseDatabase(m_dbHandle);
            m_dbHandle = 0;
        }
    }

    // Execute SQL query
    bool ExecuteSQLQuery(const string &query, string &errorMsg)
    {
        char errmsg[256];

        // Convert the string 'query' to a null-terminated char array
        char queryCharArray[4096]; // Ensure this size is sufficient for your queries
        StringToCharArray(query, queryCharArray, 0, StringLen(query) + 1);

        // Call ExecuteSQL with the char array
        int execResult = ExecuteSQL(m_dbHandle, queryCharArray, errmsg, sizeof(errmsg));
        errorMsg = CharArrayToString(errmsg);
        return (execResult == 0);
    }

    // Create tables
    bool CreateTables()
    {
        string errorMsg;
        // Create 'trades' table
        string createTradesTable = "CREATE TABLE IF NOT EXISTS trades ("
            + "TradeID INTEGER PRIMARY KEY AUTOINCREMENT, "
            + "EntryDate TEXT, EntryTime TEXT, ExitDate TEXT, ExitTime TEXT, "
            + "Symbol TEXT, TradeType TEXT, EntryPrice REAL, ExitPrice REAL, "
            + "ReasonEntry TEXT, ReasonExit TEXT, ProfitLoss REAL, Swap REAL, Commission REAL, "
            + "ATR REAL, WPRValue REAL, Duration INTEGER, LotSize REAL, Remarks TEXT);";

        // Debug print
        Print("Executing SQL Query: ", createTradesTable);

        if (!ExecuteSQLQuery(createTradesTable, errorMsg))
        {
            PrintFormat("Failed to create 'trades' table. Error: %s", errorMsg);
            return false;
        }

        // Create 'TradeLog' table
        string createTradeLogTable = "CREATE TABLE IF NOT EXISTS TradeLog ("
            + "LogID INTEGER PRIMARY KEY AUTOINCREMENT, "
            + "Date TEXT, Time TEXT, Symbol TEXT, Remarks TEXT, ATR REAL);";

        Print("Executing SQL Query: ", createTradeLogTable);

        if (!ExecuteSQLQuery(createTradeLogTable, errorMsg))
        {
            PrintFormat("Failed to create 'TradeLog' table. Error: %s", errorMsg);
            return false;
        }

        // Create 'LogEntries' table
        string createLogEntriesTable = "CREATE TABLE IF NOT EXISTS LogEntries ("
            + "LogID INTEGER PRIMARY KEY AUTOINCREMENT, "
            + "Date TEXT, Time TEXT, LogLevel TEXT, Category TEXT, Message TEXT);";

        Print("Executing SQL Query: ", createLogEntriesTable);

        if (!ExecuteSQLQuery(createLogEntriesTable, errorMsg))
        {
            PrintFormat("Failed to create 'LogEntries' table. Error: %s", errorMsg);
            return false;
        }

        return true;
    }

    // Get the database handle
    ulong GetDBHandle()
    {
        return m_dbHandle;
    }

    // Export trade logs to CSV
    bool ExportTradeLogsToCSV(string csvFilePath)
    {
        if (m_dbHandle == 0)
        {
            Print("Database handle is invalid. Cannot export trade logs.");
            return false;
        }

        char errorMsg[256];

        // Convert csvFilePath to a null-terminated char array
        char csvFilePathCharArray[512];
        StringToCharArray(csvFilePath, csvFilePathCharArray, 0, StringLen(csvFilePath) + 1);

        // Call the ExportTradeLogsToCSV function from DatabaseImports.mqh
        int result = ::ExportTradeLogsToCSV(m_dbHandle, csvFilePathCharArray, errorMsg, sizeof(errorMsg));
        if (result != 0)
        {
            // Convert errorMsg to string before printing
            string errorMsgStr = CharArrayToString(errorMsg);
            PrintFormat("Error exporting trade logs to CSV. Error: %s", errorMsgStr);
            return false;
        }
        else
        {
            Print("Trade logs exported to CSV successfully.");
            return true;
        }
    }
};

#endif // __DATABASEMANAGER_MQH__
