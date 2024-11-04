//+------------------------------------------------------------------+
//|                                               SQLiteTest.mq5     |
//|                        Your Name                                 |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property version   "1.00"
#property strict

// Import the functions from the SQLiteWrapper.dll
#import "SQLiteWrapper.dll"
long OpenDatabase(const char &filename[], char &errmsg[], int errmsgSize);
int  CloseDatabase(long dbHandle);
int  ExecuteSQL(long dbHandle, const char &query[], char &errmsg[], int errmsgSize);
#import

int OnInit()
{
    // Get the path to the tester's Files directory
    string filesDir = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files";
    string dbPath = filesDir + "\\TradeLog.db";

    // Convert dbPath to a char array
    char filePath[512];
    StringToCharArray(dbPath, filePath);

    // Print the paths for debugging
    Print("Files directory: ", filesDir);
    Print("Database path: ", dbPath);

    // Removed the DirectoryExists check

    // Database handle and error message buffer
    long dbHandle = 0;
    char errorMsg[256];

    // Attempt to open the database
    long result = OpenDatabase(filePath, errorMsg, sizeof(errorMsg));
    if (result == 0)
    {
        PrintFormat("Failed to open database. Error: %s, Result: %d", CharArrayToString(errorMsg), result);
        return INIT_FAILED;
    }
    else
    {
        dbHandle = result;
    }

    Print("Database opened successfully.");

    // SQL query to create a table
    string createTableQuery = "CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY, test_column TEXT);";
    char query[512];
    StringToCharArray(createTableQuery, query);

    // Execute the SQL statement
    int execResult = ExecuteSQL(dbHandle, query, errorMsg, sizeof(errorMsg));
    if (execResult != 0)
    {
        PrintFormat("Error executing SQL. Error: %s, Result: %d", CharArrayToString(errorMsg), execResult);
        CloseDatabase(dbHandle);
        return INIT_FAILED;
    }
    Print("Table created successfully.");

    // Close the database
    int closeResult = CloseDatabase(dbHandle);
    if (closeResult != 0)
    {
        Print("Failed to close the database.");
        return INIT_FAILED;
    }
    Print("Database closed successfully.");

    return INIT_SUCCEEDED;
}