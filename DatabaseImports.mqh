// DatabaseImports.mqh

#ifndef __DATABASEIMPORTS_MQH__
#define __DATABASEIMPORTS_MQH__

#import "SQLiteWrapper.dll"
   long OpenDatabase(const char &filename[], char &errmsg[], int errmsgSize);
   int CloseDatabase(long dbHandle);
   int ExecuteSQL(long dbHandle, const char &sql[], char &errmsg[], int errmsgSize);
   int ExportTradeLogsToCSV(long dbHandle, const char &csvFilePath[], char &errmsg[], int errmsgSize);
   // Note: Removed transaction function imports
#import

#endif // __DATABASEIMPORTS_MQH__
