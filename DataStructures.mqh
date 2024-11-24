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
   double adxValue;        // ADX value
   double pivotPoint;      // Pivot Point value
   double resistance1;     // R1
   double support1;        // S1
   double highVolumeLevel; // High Volume Level
   double lowVolumeLevel;  // Low Volume Level
   double lotSize;
   string reasonEntry;
   string strategyUsed;    // Strategy used for the trade
   string date;
   string time;
   double currentStopLoss; // Field to track current Stop Loss
   double takeProfitPrice;
   int profitLevelReached; // Field to track profit levels reached
   bool trailingStopActivated;       // Indicates if trailing stop was activated
   double profitLevelAtTrailingStop; // Stores profit level at trailing stop activation
   bool isLogged;                    // Field to indicate if the position has been logged
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
   double swap;               // Swap
   double commission;         // Commission
   double atr;
   double wprValue;           // Williams %R value
   double adxValue;           // ADX value
   double pivotPoint;         // Pivot Point value
   double resistance1;        // R1
   double support1;           // S1
   double highVolumeLevel;    // High Volume Level
   double lowVolumeLevel;     // Low Volume Level
   string strategyUsed;       // Strategy used for the trade
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
