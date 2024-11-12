// Utils.mqh

#ifndef __UTILS_MQH__
#define __UTILS_MQH__

string SanitizeForSQL(string text) {
    StringReplace(text, "'", "''");
    return text;
}

//+------------------------------------------------------------------+
//| Error Description Function                                       |
//+------------------------------------------------------------------+
string ErrorDescription(int errorCode)
{
    switch(errorCode)
    {
        case 0: return "No error";
        case 1: return "No result, but error is unknown";
        case 2: return "Common error";
        case 3: return "Invalid trade parameters";
        case 4: return "Trade server busy";
        case 5: return "Old version of the client terminal";
        case 6: return "No connection with trade server";
        case 7: return "Not enough rights";
        case 8: return "Too frequent requests";
        case 9: return "Malfunctional trade operation";
        case 10: return "Invalid account";
        case 11: return "Invalid price";
        case 12: return "Invalid stops";
        case 13: return "Invalid trade volume";
        case 14: return "Market closed";
        case 15: return "Trade disabled";
        case 16: return "Not enough money";
        case 17: return "Price changed";
        case 18: return "Off quotes";
        case 19: return "Broker is busy";
        case 20: return "Requote";
        case 21: return "Order locked";
        case 22: return "Long positions only allowed";
        case 23: return "Too many requests";
        case 24: return "Trade timeout";
        case 25: return "Invalid order fill";
        case 26: return "Order already exists";
        case 27: return "Order modified";
        case 28: return "Trade context busy";
        case 29: return "Trade timeout";
        case 30: return "Invalid trade";
        case 31: return "Trade disabled";
        // Add more cases as needed...
        default: return "Unknown or custom error code";  // Default for unexpected error codes
    }
}

//+------------------------------------------------------------------+
//| Format Error Message Function                                    |
//+------------------------------------------------------------------+
string FormatErrorMessage(uint errorCode, string errorDescription) {
    return "Error " + IntegerToString(errorCode) + ": " + errorDescription;
}

//+------------------------------------------------------------------+
//| Timer Function for Profiling                                     |
//+------------------------------------------------------------------+
ulong GetTimeInMilliseconds()
{
    return GetTickCount64();
}

// Get current tick count in milliseconds
ulong GetCustomTickCount()
{
    // Returns the number of milliseconds that have elapsed since the system was started.
    return (ulong)(GetMicrosecondCount() / 1000);
}

#endif // __UTILS_MQH__
