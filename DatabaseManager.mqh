// DatabaseManager.mqh

#ifndef __DATABASEMANAGER_MQH__
#define __DATABASEMANAGER_MQH__

#include "DatabaseImports.mqh"
#include "DataStructures.mqh"   // Include TradeData definition
#include "Utils.mqh"            // For StringReplace and other utility functions

// Import ShellExecute function from shell32.dll for opening CSV in Excel
#import "shell32.dll"
int ShellExecuteW(int hwnd, string Operation, string File, string Parameters, string Directory, int ShowCmd);
#import

// Import transaction functions directly into DatabaseManager
#import "SQLiteWrapper.dll"
   int BeginTransaction(long dbHandle, char &errmsg[], int errmsgSize);
   int CommitTransaction(long dbHandle, char &errmsg[], int errmsgSize);
   int RollbackTransaction(long dbHandle, char &errmsg[], int errmsgSize);
#import

class CDatabaseManager
{
private:
    ulong m_dbHandle;
    string m_dbPath;
    bool m_isConnected; // Track connection status

    // Nested TransactionManager class within CDatabaseManager
    class CTransactionManager
    {
    private:
        ulong m_dbHandle;
        bool m_inTransaction; // Track if a transaction is in progress

    public:
        // Default Constructor
        CTransactionManager()
        {
            m_dbHandle = 0;
            m_inTransaction = false;
        }

        // Initialize with dbHandle
        void Init(ulong dbHandle)
        {
            m_dbHandle = dbHandle;
            m_inTransaction = false;
        }

        // Begin Transaction
        bool BeginTransaction()
        {
            char errmsg[256];
            int result = ::BeginTransaction(m_dbHandle, errmsg, sizeof(errmsg));
            if (result != 0)
            {
                PrintFormat("Failed to begin transaction. Error: %s", CharArrayToString(errmsg));
                return false;
            }
            m_inTransaction = true;
            return true;
        }

        // Commit Transaction
        bool CommitTransaction()
        {
            if (!m_inTransaction)
            {
                Print("No transaction in progress to commit.");
                return false;
            }

            char errmsg[256];
            int result = ::CommitTransaction(m_dbHandle, errmsg, sizeof(errmsg));
            if (result != 0)
            {
                PrintFormat("Failed to commit transaction. Error: %s", CharArrayToString(errmsg));
                return false;
            }
            m_inTransaction = false;
            return true;
        }

        // Rollback Transaction
        bool RollbackTransaction()
        {
            if (!m_inTransaction)
            {
                Print("No transaction in progress to rollback.");
                return false;
            }

            char errmsg[256];
            int result = ::RollbackTransaction(m_dbHandle, errmsg, sizeof(errmsg));
            if (result != 0)
            {
                PrintFormat("Failed to rollback transaction. Error: %s", CharArrayToString(errmsg));
                return false;
            }
            m_inTransaction = false;
            return true;
        }

        // Check if in transaction
        bool IsInTransaction()
        {
            return m_inTransaction;
        }
    };

    // Instance of TransactionManager
    CTransactionManager m_transactionManager;

public:
    // Default Constructor
    CDatabaseManager()
    {
        m_dbHandle = 0; // Initialize dbHandle to 0
        m_isConnected = false;
    }

    // Destructor
    ~CDatabaseManager()
    {
        CloseDatabaseConnection();
    }

    // Init method to set the database path
    void Init(string dbPathParam)
    {
        m_dbPath = dbPathParam;
    }

    // Open database connection
    bool OpenDatabaseConnection()
    {
        char errorMsg[256];
        char dbPathCharArray[512];
        StringToCharArray(m_dbPath, dbPathCharArray, 0, StringLen(m_dbPath) + 1);

        m_dbHandle = OpenDatabase(dbPathCharArray, errorMsg, sizeof(errorMsg));
        if (m_dbHandle == 0)
        {
            PrintFormat("Failed to open database. Error: %s", CharArrayToString(errorMsg));
            m_isConnected = false;
            return false;
        }

        // Initialize the transaction manager with the dbHandle
        m_transactionManager.Init(m_dbHandle);
        m_isConnected = true;
        return true;
    }

    // Close database connection
    void CloseDatabaseConnection()
    {
        if (m_dbHandle != 0)
        {
            // If a transaction is in progress, rollback
            if (m_transactionManager.IsInTransaction())
            {
                m_transactionManager.RollbackTransaction();
            }
            CloseDatabase(m_dbHandle);
            m_dbHandle = 0;
            m_isConnected = false;
        }
    }

    // Check if the database is connected
    bool IsConnected()
    {
        return m_isConnected;
    }

    // Expose transaction manager methods
    bool BeginTransaction()
    {
        if (!IsConnected())
        {
            Print("Database is not connected. Cannot begin transaction.");
            return false;
        }
        return m_transactionManager.BeginTransaction();
    }

    bool CommitTransaction()
    {
        if (!IsConnected())
        {
            Print("Database is not connected. Cannot commit transaction.");
            return false;
        }
        return m_transactionManager.CommitTransaction();
    }

    bool RollbackTransaction()
    {
        if (!IsConnected())
        {
            Print("Database is not connected. Cannot rollback transaction.");
            return false;
        }
        return m_transactionManager.RollbackTransaction();
    }

    // Execute SQL query
    bool ExecuteSQLQuery(const string &query, string &errorMsg)
    {
        if (!IsConnected())
        {
            errorMsg = "Database is not connected.";
            return false;
        }

        char errmsg[256];
        char queryCharArray[4096];
        StringToCharArray(query, queryCharArray, 0, StringLen(query) + 1);

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
                                   "TradeID INTEGER PRIMARY KEY AUTOINCREMENT, "
                                   "EntryDate TEXT, EntryTime TEXT, ExitDate TEXT, ExitTime TEXT, "
                                   "Symbol TEXT, TradeType TEXT, EntryPrice REAL, ExitPrice REAL, "
                                   "ReasonEntry TEXT, ReasonExit TEXT, ProfitLoss REAL, Swap REAL, Commission REAL, "
                                   "ATR REAL, WPRValue REAL, Duration INTEGER, LotSize REAL, Remarks TEXT);";

        if (!ExecuteSQLQuery(createTradesTable, errorMsg))
        {
            PrintFormat("Failed to create 'trades' table. Error: %s", errorMsg);
            return false;
        }

        // Create 'TradeLog' table
        string createTradeLogEntries = "CREATE TABLE IF NOT EXISTS TradeLog ("
                                       "LogID INTEGER PRIMARY KEY AUTOINCREMENT, "
                                       "Date TEXT, Time TEXT, Symbol TEXT, Remarks TEXT, ATR REAL);";

        if (!ExecuteSQLQuery(createTradeLogEntries, errorMsg))
        {
            PrintFormat("Failed to create 'TradeLog' table. Error: %s", errorMsg);
            return false;
        }

        // Create 'LogEntries' table
        string createLogEntriesTable = "CREATE TABLE IF NOT EXISTS LogEntries ("
                                       "LogID INTEGER PRIMARY KEY AUTOINCREMENT, "
                                       "Date TEXT, Time TEXT, LogLevel TEXT, Category TEXT, Message TEXT);";

        if (!ExecuteSQLQuery(createLogEntriesTable, errorMsg))
        {
            PrintFormat("Failed to create 'LogEntries' table. Error: %s", errorMsg);
            return false;
        }

        // Create 'ErrorAggregations' table
        string createErrorAggregationsTable = "CREATE TABLE IF NOT EXISTS ErrorAggregations ("
                                              "ErrorCode INTEGER, "
                                              "ErrorMessage TEXT, "
                                              "Count INTEGER, "
                                              "FirstOccurrence TEXT, "
                                              "LastOccurrence TEXT, "
                                              "UNIQUE (ErrorCode, ErrorMessage));";

        if (!ExecuteSQLQuery(createErrorAggregationsTable, errorMsg))
        {
            PrintFormat("Failed to create 'ErrorAggregations' table. Error: %s", errorMsg);
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
    bool ExportTradeLogsToCSV(string csvFilePath, bool openFileAfterExport = true)
    {
        if (!IsConnected())
        {
            Print("Database is not connected. Cannot export trade logs.");
            return false;
        }

        char errorMsg[256];
        char csvFilePathCharArray[512];
        StringToCharArray(csvFilePath, csvFilePathCharArray, 0, StringLen(csvFilePath) + 1);

        int result = ::ExportTradeLogsToCSV(m_dbHandle, csvFilePathCharArray, errorMsg, sizeof(errorMsg));
        if (result != 0)
        {
            string errorMsgStr = CharArrayToString(errorMsg);
            PrintFormat("Error exporting trade logs to CSV. Error: %s", errorMsgStr);
            return false;
        }
        else
        {
            Print("Trade logs exported to CSV successfully.");

            // Check if DLL imports are allowed before opening the file
            if (openFileAfterExport && TerminalInfoInteger(TERMINAL_DLLS_ALLOWED))
            {
                return OpenCSVFileInExcel(csvFilePath);
            }
            return true;
        }
    }

    // Open CSV file in Excel using ShellExecuteW
    bool OpenCSVFileInExcel(string csvFilePath)
    {
        int res = ShellExecuteW(0, "open", csvFilePath, "", "", 1);
        if (res <= 32)
        {
            Print("Failed to open the CSV file in Excel.");
            return false;
        }
        return true;
    }

    // LogTrade method with transaction handling
    void LogTrade(TradeData &tradeData)
    {
        if (!IsConnected())
        {
            Print("Database is not connected. Cannot log trade.");
            return;
        }

        // Begin transaction
        if (!BeginTransaction())
        {
            Print("Failed to begin transaction for logging trade.");
            return;
        }

        // Sanitize strings for SQL
        string sanitizedReasonEntry = tradeData.reasonEntry;
        string sanitizedReasonExit = tradeData.reasonExit;
        string sanitizedRemarks = tradeData.remarks;
        StringReplace(sanitizedReasonEntry, "'", "''");
        StringReplace(sanitizedReasonExit, "'", "''");
        StringReplace(sanitizedRemarks, "'", "''");

        // Prepare SQL INSERT statement without TradeID
        string insertQuery = "INSERT INTO trades (EntryDate, EntryTime, ExitDate, ExitTime, Symbol, TradeType, EntryPrice, ExitPrice, "
                             "ReasonEntry, ReasonExit, ProfitLoss, Swap, Commission, ATR, WPRValue, Duration, LotSize, Remarks) VALUES (" +
                             "'" + tradeData.entryDate + "'," +
                             "'" + tradeData.entryTime + "'," +
                             "'" + tradeData.exitDate + "'," +
                             "'" + tradeData.exitTime + "'," +
                             "'" + tradeData.symbol + "'," +
                             "'" + tradeData.tradeType + "'," +
                             DoubleToString(tradeData.entryPrice, _Digits) + "," +
                             DoubleToString(tradeData.exitPrice, _Digits) + "," +
                             "'" + sanitizedReasonEntry + "'," +
                             "'" + sanitizedReasonExit + "'," +
                             DoubleToString(tradeData.profitLoss, 2) + "," +
                             DoubleToString(tradeData.swap, 2) + "," +           // Include swap
                             DoubleToString(tradeData.commission, 2) + "," +    // Include commission
                             DoubleToString(tradeData.atr, _Digits) + "," +
                             DoubleToString(tradeData.wprValue, 2) + "," +
                             IntegerToString(tradeData.duration) + "," +
                             DoubleToString(tradeData.lotSize, 2) + "," +
                             "'" + sanitizedRemarks + "');";

        string errorMsg;
        if (!ExecuteSQLQuery(insertQuery, errorMsg))
        {
            Print("Error inserting trade log to database: " + errorMsg);
            // Rollback transaction
            RollbackTransaction();
        }
        else
        {
            // Commit transaction
            if (!CommitTransaction())
            {
                Print("Failed to commit transaction after logging trade.");
            }
            else
            {
                Print("Trade logged to database successfully.");
            }
        }
    }

    // Additional methods can utilize the TransactionManager for batch operations
};

#endif // __DATABASEMANAGER_MQH__
