// DataStructures.mqh
#ifndef __DATASTRUCTURES_MQH__
#define __DATASTRUCTURES_MQH__

struct OpenPositionData
{
   ulong positionID;
   ulong entryDealTicket;
   string symbol;
   string tradeType;       // "Buy" or "Sell"
   double entryPrice;
   datetime entryTime;
   double atr;
   double wprValue;        // Williams %R value
   double lotSize;
   string reasonEntry;
   string date;
   string time;
   double currentStopLoss; // Field to track current Stop Loss
   double takeProfitPrice;
   int profitLevelReached; // Field to track profit levels reached
   bool trailingStopActivated;       // Indicates if trailing stop was activated
   double profitLevelAtTrailingStop; // Stores profit level at trailing stop activation
   bool isLogged;                    // New field to indicate if the position has been logged
};

struct TradeData
{
   ulong positionID;          // Position ID
   string symbol;
   string tradeType;
   double entryPrice;
   double exitPrice;
   double lotSize;
   string entryDate;
   string entryTime;
   string exitDate;
   string exitTime;
   long duration;
   string reasonEntry;
   string reasonExit;
   double profitLoss;
   double swap;               // Added field for swap
   double commission;         // Added field for commission
   double atr;
   double wprValue;           // Williams %R value
   string remarks;
};

// Structure to store aggregated error data
struct AggregatedError
{
   int errorCode;
   string errorMessage;
   int count;
   datetime firstOccurrence;
   datetime lastOccurrence;
};

#endif // __DATASTRUCTURES_MQH__
