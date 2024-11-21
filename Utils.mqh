// Utils.mqh

#ifndef __UTILS_MQH__
#define __UTILS_MQH__

// Define error codes if not already defined using conditional compilation
#ifndef ERR_NO_ERROR
#define ERR_NO_ERROR                        0
#endif

#ifndef ERR_NO_RESULT
#define ERR_NO_RESULT                       1
#endif

#ifndef ERR_COMMON_ERROR
#define ERR_COMMON_ERROR                    2
#endif

#ifndef ERR_INVALID_TRADE_PARAMETERS
#define ERR_INVALID_TRADE_PARAMETERS        3
#endif

#ifndef ERR_SERVER_BUSY
#define ERR_SERVER_BUSY                     4
#endif

#ifndef ERR_OLD_VERSION
#define ERR_OLD_VERSION                     5
#endif

#ifndef ERR_NO_CONNECTION
#define ERR_NO_CONNECTION                   6
#endif

#ifndef ERR_NOT_ENOUGH_RIGHTS
#define ERR_NOT_ENOUGH_RIGHTS               7
#endif

#ifndef ERR_TOO_FREQUENT_REQUESTS
#define ERR_TOO_FREQUENT_REQUESTS           8
#endif

#ifndef ERR_MALFUNCTIONAL_TRADE
#define ERR_MALFUNCTIONAL_TRADE             9
#endif

#ifndef ERR_INVALID_ACCOUNT
#define ERR_INVALID_ACCOUNT                 10
#endif

#ifndef ERR_INVALID_PRICE
#define ERR_INVALID_PRICE                   11
#endif

#ifndef ERR_INVALID_STOPS
#define ERR_INVALID_STOPS                   12
#endif

#ifndef ERR_INVALID_TRADE_VOLUME
#define ERR_INVALID_TRADE_VOLUME            13
#endif

#ifndef ERR_MARKET_CLOSED
#define ERR_MARKET_CLOSED                   14
#endif

#ifndef ERR_TRADE_DISABLED
#define ERR_TRADE_DISABLED                  15
#endif

#ifndef ERR_NOT_ENOUGH_MONEY
#define ERR_NOT_ENOUGH_MONEY                16
#endif

#ifndef ERR_PRICE_CHANGED
#define ERR_PRICE_CHANGED                   17
#endif

#ifndef ERR_OFF_QUOTES
#define ERR_OFF_QUOTES                      18
#endif

#ifndef ERR_BROKER_BUSY
#define ERR_BROKER_BUSY                     19
#endif

#ifndef ERR_REQUOTE
#define ERR_REQUOTE                         20
#endif

#ifndef ERR_ORDER_LOCKED
#define ERR_ORDER_LOCKED                    21
#endif

#ifndef ERR_LONG_POSITIONS_ONLY_ALLOWED
#define ERR_LONG_POSITIONS_ONLY_ALLOWED     22
#endif

#ifndef ERR_TOO_MANY_REQUESTS
#define ERR_TOO_MANY_REQUESTS               23
#endif

#ifndef ERR_TRADE_TIMEOUT
#define ERR_TRADE_TIMEOUT                   24
#endif

#ifndef ERR_INVALID_ORDER_FILL
#define ERR_INVALID_ORDER_FILL              25
#endif

#ifndef ERR_ORDER_EXISTS
#define ERR_ORDER_EXISTS                    26
#endif

#ifndef ERR_ORDER_MODIFY_DENIED
#define ERR_ORDER_MODIFY_DENIED             27
#endif

#ifndef ERR_TRADE_CONTEXT_BUSY
#define ERR_TRADE_CONTEXT_BUSY              28
#endif

#ifndef ERR_TRADE_EXPIRATION_DENIED
#define ERR_TRADE_EXPIRATION_DENIED         29
#endif

#ifndef ERR_TRADE_TOO_MANY_ORDERS
#define ERR_TRADE_TOO_MANY_ORDERS           30
#endif

#ifndef ERR_TRADE_TOO_MANY_VOLUME
#define ERR_TRADE_TOO_MANY_VOLUME           31
#endif

// Add more error codes as needed...

// Existing functions

string SanitizeForSQL(string text)
{
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
        case ERR_NO_ERROR:                        return "No error";
        case ERR_NO_RESULT:                       return "No result, but error is unknown";
        case ERR_COMMON_ERROR:                    return "Common error";
        case ERR_INVALID_TRADE_PARAMETERS:        return "Invalid trade parameters";
        case ERR_SERVER_BUSY:                     return "Trade server busy";
        case ERR_OLD_VERSION:                     return "Old version of the client terminal";
        case ERR_NO_CONNECTION:                   return "No connection with trade server";
        case ERR_NOT_ENOUGH_RIGHTS:               return "Not enough rights";
        case ERR_TOO_FREQUENT_REQUESTS:           return "Too frequent requests";
        case ERR_MALFUNCTIONAL_TRADE:             return "Malfunctional trade operation";
        case ERR_INVALID_ACCOUNT:                 return "Invalid account";
        case ERR_INVALID_PRICE:                   return "Invalid price";
        case ERR_INVALID_STOPS:                   return "Invalid stops";
        case ERR_INVALID_TRADE_VOLUME:            return "Invalid trade volume";
        case ERR_MARKET_CLOSED:                   return "Market closed";
        case ERR_TRADE_DISABLED:                  return "Trade disabled";
        case ERR_NOT_ENOUGH_MONEY:                return "Not enough money";
        case ERR_PRICE_CHANGED:                   return "Price changed";
        case ERR_OFF_QUOTES:                      return "Off quotes";
        case ERR_BROKER_BUSY:                     return "Broker is busy";
        case ERR_REQUOTE:                         return "Requote";
        case ERR_ORDER_LOCKED:                    return "Order locked";
        case ERR_LONG_POSITIONS_ONLY_ALLOWED:     return "Long positions only allowed";
        case ERR_TOO_MANY_REQUESTS:               return "Too many requests";
        case ERR_TRADE_TIMEOUT:                   return "Trade timeout";
        case ERR_INVALID_ORDER_FILL:              return "Invalid order fill";
        case ERR_ORDER_EXISTS:                    return "Order already exists";
        case ERR_ORDER_MODIFY_DENIED:             return "Order modify denied";
        case ERR_TRADE_CONTEXT_BUSY:              return "Trade context busy";
        case ERR_TRADE_EXPIRATION_DENIED:         return "Trade expiration denied";
        case ERR_TRADE_TOO_MANY_ORDERS:           return "Too many orders";
        case ERR_TRADE_TOO_MANY_VOLUME:           return "Too much volume";
        // Add more cases as needed...
        default: return "Unknown or custom error code";  // Default for unexpected error codes
    }
}

//+------------------------------------------------------------------+
//| Format Error Message Function                                    |
//+------------------------------------------------------------------+
string FormatErrorMessage(uint errorCode, string errorDescription)
{
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

//+------------------------------------------------------------------+
//| Validate Indicator Value                                         |
//+------------------------------------------------------------------+
bool IsValidValue(double value)
{
    return MathIsValidNumber(value);
}

//+------------------------------------------------------------------+
//| Get Reason Exit String                                           |
//+------------------------------------------------------------------+
string GetReasonExitString(ENUM_DEAL_REASON reason)
{
    switch (reason)
    {
        case DEAL_REASON_SL:
            return "Stop Loss Hit";
        case DEAL_REASON_TP:
            return "Take Profit Hit";
        case DEAL_REASON_SO:
            return "Stop Out";
        case DEAL_REASON_CLIENT:
            return "Closed Manually";
        case DEAL_REASON_EXPERT:
            return "Closed by Expert";
        // Add other cases as needed
        default:
            return "Unknown Reason";
    }
}

#endif // __UTILS_MQH__
