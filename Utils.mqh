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
        // More cases can be added as needed...
        default: return "Unknown or custom error code";  // Default for unexpected error codes
    }
}

#endif // __UTILS_MQH__
