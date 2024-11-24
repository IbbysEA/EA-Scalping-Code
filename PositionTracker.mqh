// PositionTracker.mqh

#ifndef __POSITIONTRACKER_MQH__
#define __POSITIONTRACKER_MQH__

#include <Trade\Trade.mqh>
#include "DataStructures.mqh"
#include "Logger.mqh"
#include "LogManager.mqh"
#include "GlobalVariables.mqh"
#include "DatabaseManager.mqh"
#include "GlobalDefinitions.mqh"
#include "Utils.mqh"

// Externally defined variables and instances
extern CLogManager    logManager;
extern CDatabaseManager dbManager;
extern CTrade         trade;

class PositionTracker
{
private:
    OpenPositionData positions[];
    ulong loggedPositionIDs[];
    int m_magicNumber;
    int m_slippage;

public:
    // Constructor and Destructor
    PositionTracker(int magicNumber, int slippage)
    {
        m_magicNumber = magicNumber;
        m_slippage = slippage;
    }

    ~PositionTracker()
    {
        // Cleanup if needed
    }

    // Existing methods
    void AddPosition(const OpenPositionData &positionData);
    void RemovePositionByIndex(int index);
    int  FindPositionIndex(ulong positionID);
    bool GetPositionData(ulong positionID, OpenPositionData &outPositionData);
    void UpdatePositionData(ulong positionID, const OpenPositionData &positionData);
    int  GetTotalPositions();
    bool GetPositionByIndex(int index, OpenPositionData &outPositionData);
    void ClearAllPositions();

    // New methods
    bool IsPositionLogged(ulong positionID);
    void AddLoggedPosition(ulong positionID);
    ulong FindClosingDealForPosition(ulong positionID);
    ulong FindOpeningDealForPosition(ulong positionID);
    ulong FindLastDealForPosition(ulong positionID);
    void LogClosedTrade(ulong positionID, ulong closingDealTicket);
    void HandleOpenPositionsOnDeinit();

    // Method to close all positions
    void CloseAllPositions();

private:
    void LogTrade(TradeData &tradeData);
};

// Implementation of PositionTracker methods

void PositionTracker::AddPosition(const OpenPositionData &positionData)
{
    int size = ArraySize(positions);
    ArrayResize(positions, size + 1);
    positions[size] = positionData;
    logManager.LogMessage("Position added to tracker. Position ID: " + IntegerToString(positionData.positionID), LOG_LEVEL_DEBUG);
}

void PositionTracker::RemovePositionByIndex(int index)
{
    int size = ArraySize(positions);
    if (index >= 0 && index < size)
    {
        for (int i = index; i < size - 1; i++)
        {
            positions[i] = positions[i + 1];
        }
        ArrayResize(positions, size - 1);
        logManager.LogMessage("Position removed from tracker at index: " + IntegerToString(index), LOG_LEVEL_DEBUG);
    }
}

int PositionTracker::FindPositionIndex(ulong positionID)
{
    int size = ArraySize(positions);
    for (int i = 0; i < size; i++)
    {
        if (positions[i].positionID == positionID)
        {
            return i;
        }
    }
    return -1;
}

bool PositionTracker::GetPositionData(ulong positionID, OpenPositionData &outPositionData)
{
    int index = FindPositionIndex(positionID);
    if (index != -1)
    {
        outPositionData = positions[index];
        return true;
    }
    return false;
}

void PositionTracker::UpdatePositionData(ulong positionID, const OpenPositionData &updatedData)
{
    int index = FindPositionIndex(positionID);
    if (index != -1)
    {
        positions[index] = updatedData;
        logManager.LogMessage("Position data updated for Position ID: " + IntegerToString(positionID), LOG_LEVEL_DEBUG);
    }
}

int PositionTracker::GetTotalPositions()
{
    return ArraySize(positions);
}

bool PositionTracker::GetPositionByIndex(int index, OpenPositionData &outPositionData)
{
    if (index >= 0 && index < ArraySize(positions))
    {
        outPositionData = positions[index];
        return true;
    }
    return false;
}

void PositionTracker::ClearAllPositions()
{
    ArrayResize(positions, 0);
    logManager.LogMessage("All positions cleared from PositionTracker.", LOG_LEVEL_INFO);
}

bool PositionTracker::IsPositionLogged(ulong positionID)
{
    for (int i = 0; i < ArraySize(loggedPositionIDs); i++)
    {
        if (loggedPositionIDs[i] == positionID)
            return true;
    }
    return false;
}

void PositionTracker::AddLoggedPosition(ulong positionID)
{
    int size = ArraySize(loggedPositionIDs);
    ArrayResize(loggedPositionIDs, size + 1);
    loggedPositionIDs[size] = positionID;
}

ulong PositionTracker::FindClosingDealForPosition(ulong positionID)
{
    // Ensure the history is refreshed
    HistorySelect(0, TimeCurrent());

    // Get the number of deals in history
    int totalDeals = HistoryDealsTotal();
    for (int i = totalDeals - 1; i >= 0; i--)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        if (HistoryDealSelect(dealTicket))
        {
            ulong dealPositionID = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
            if (dealPositionID == positionID)
            {
                ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                if (dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
                {
                    // Closing deal found
                    return dealTicket;
                }
            }
        }
    }
    return 0; // No closing deal found
}

ulong PositionTracker::FindOpeningDealForPosition(ulong positionID)
{
    // Ensure the history is refreshed
    HistorySelect(0, TimeCurrent());

    // Get the number of deals in history
    int totalDeals = HistoryDealsTotal();
    for (int i = totalDeals - 1; i >= 0; i--)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        if (HistoryDealSelect(dealTicket))
        {
            ulong dealPositionID = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
            if (dealPositionID == positionID)
            {
                ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                if (dealEntry == DEAL_ENTRY_IN)
                {
                    // Opening deal found
                    return dealTicket;
                }
            }
        }
    }
    return 0; // No opening deal found
}

ulong PositionTracker::FindLastDealForPosition(ulong positionID)
{
    // Ensure the history is refreshed
    HistorySelect(0, TimeCurrent());

    // Get the number of deals in history
    int totalDeals = HistoryDealsTotal();
    for (int i = 0; i < totalDeals; i++)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        if (HistoryDealSelect(dealTicket))
        {
            ulong dealPositionID = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
            if (dealPositionID == positionID)
            {
                return dealTicket;
            }
        }
    }
    return 0; // No deal found
}

void PositionTracker::LogClosedTrade(ulong positionID, ulong closingDealTicket)
{
    // Check if the positionID has already been logged
    if (IsPositionLogged(positionID))
    {
        if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
        {
            string logMsg = "Position ID " + IntegerToString(positionID) + " has already been logged. Skipping.";
            LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, logMsg);
        }
        return;
    }

    // Ensure the closing deal exists in history
    if (!HistoryDealSelect(closingDealTicket))
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_EXECUTION, "Failed to select closing deal " + IntegerToString(closingDealTicket));
        return;
    }

    // Attempt to find the open position data
    OpenPositionData entryData;
    if (!GetPositionData(positionID, entryData))
    {
        // Entry data not found; reconstruct trade data from deals
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_EXECUTION, "Open position data not found for position ID: " + IntegerToString(positionID));

        // Reconstruct trade data from deals
        ulong openingDealTicket = FindOpeningDealForPosition(positionID);

        if (openingDealTicket == 0)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_EXECUTION, "Failed to find opening deal for position ID: " + IntegerToString(positionID));
            return;
        }

        // Prepare trade data using opening and closing deals
        TradeData tradeData;
        tradeData.positionID = positionID;
        tradeData.entryPrice = HistoryDealGetDouble(openingDealTicket, DEAL_PRICE);
        tradeData.exitPrice = HistoryDealGetDouble(closingDealTicket, DEAL_PRICE);
        tradeData.lotSize = HistoryDealGetDouble(openingDealTicket, DEAL_VOLUME);
        tradeData.symbol = HistoryDealGetString(openingDealTicket, DEAL_SYMBOL);
        tradeData.tradeType = (HistoryDealGetInteger(openingDealTicket, DEAL_TYPE) == DEAL_TYPE_BUY) ? "Buy" : "Sell";

        datetime entryTime = (datetime)HistoryDealGetInteger(openingDealTicket, DEAL_TIME);
        datetime exitTime = (datetime)HistoryDealGetInteger(closingDealTicket, DEAL_TIME);
        tradeData.entryDate = TimeToString(entryTime, TIME_DATE);
        tradeData.entryTime = TimeToString(entryTime, TIME_SECONDS | TIME_MINUTES);
        tradeData.exitDate = TimeToString(exitTime, TIME_DATE);
        tradeData.exitTime = TimeToString(exitTime, TIME_SECONDS | TIME_MINUTES);
        tradeData.duration = (long)(exitTime - entryTime);

        // Retrieve profit, swap, and commission
        double dealProfit = HistoryDealGetDouble(closingDealTicket, DEAL_PROFIT);
        double dealSwap = HistoryDealGetDouble(closingDealTicket, DEAL_SWAP);
        double dealCommission = HistoryDealGetDouble(closingDealTicket, DEAL_COMMISSION);

        tradeData.profitLoss = dealProfit + dealSwap + dealCommission;
        tradeData.swap = dealSwap;
        tradeData.commission = dealCommission;

        tradeData.reasonEntry = ""; // Reason not available
        ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(closingDealTicket, DEAL_REASON);
        tradeData.reasonExit = GetReasonExitString(reason);  // Use function from Utils.mqh
        tradeData.atr = 0.0;       // ATR not available
        tradeData.wprValue = 0.0;  // WPR not available
        tradeData.adxValue = 0.0;  // ADX not available
        tradeData.pivotPoint = 0.0;
        tradeData.resistance1 = 0.0;
        tradeData.support1 = 0.0;
        tradeData.highVolumeLevel = 0.0;
        tradeData.lowVolumeLevel = 0.0;
        tradeData.strategyUsed = ""; // Strategy not available
        tradeData.remarks = "Entry data not found; reconstructed from deals";

        AddLoggedPosition(positionID);

        // Log the completed trade without open position data
        if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION))
        {
            string logMsg = "Logging trade reconstructed from deals: positionID=" + IntegerToString(positionID) + ", symbol=" + tradeData.symbol + ", tradeType=" + tradeData.tradeType;
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, logMsg);
        }
        LogTrade(tradeData);
    }
    else
    {
        // Prepare trade data using stored entry data
        TradeData tradeData;

        tradeData.positionID = entryData.positionID; // Position ID from open position data
        tradeData.entryDate = entryData.date;
        tradeData.entryTime = entryData.time;
        tradeData.entryPrice = entryData.entryPrice;
        tradeData.reasonEntry = entryData.reasonEntry;
        tradeData.lotSize = entryData.lotSize;
        tradeData.duration = (long)(HistoryDealGetInteger(closingDealTicket, DEAL_TIME) - entryData.entryTime);
        tradeData.symbol = HistoryDealGetString(closingDealTicket, DEAL_SYMBOL);
        tradeData.exitPrice = HistoryDealGetDouble(closingDealTicket, DEAL_PRICE);
        tradeData.tradeType = entryData.tradeType; // Fetch trade type

        datetime exitTime = (datetime)HistoryDealGetInteger(closingDealTicket, DEAL_TIME);
        tradeData.exitDate = TimeToString(exitTime, TIME_DATE);
        tradeData.exitTime = TimeToString(exitTime, TIME_SECONDS | TIME_MINUTES);

        // Log additional relevant data
        tradeData.atr = entryData.atr;               // ATR from open position
        tradeData.wprValue = entryData.wprValue;     // Williams %R from open position
        tradeData.adxValue = entryData.adxValue;     // ADX value
        tradeData.pivotPoint = entryData.pivotPoint;
        tradeData.resistance1 = entryData.resistance1;
        tradeData.support1 = entryData.support1;
        tradeData.highVolumeLevel = entryData.highVolumeLevel;
        tradeData.lowVolumeLevel = entryData.lowVolumeLevel;
        tradeData.strategyUsed = entryData.strategyUsed;

        ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(closingDealTicket, DEAL_REASON);
        tradeData.reasonExit = GetReasonExitString(reason);  // Use function from Utils.mqh

        // Retrieve profit, swap, and commission from the closing deal
        double dealProfit = HistoryDealGetDouble(closingDealTicket, DEAL_PROFIT);
        double dealSwap = HistoryDealGetDouble(closingDealTicket, DEAL_SWAP);
        double dealCommission = HistoryDealGetDouble(closingDealTicket, DEAL_COMMISSION);

        tradeData.profitLoss = dealProfit + dealSwap + dealCommission;
        tradeData.swap = dealSwap;
        tradeData.commission = dealCommission;

        tradeData.remarks = ""; // No additional remarks needed when open data is found

        AddLoggedPosition(positionID);

        // Log the completed trade with open position data found
        if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION))
        {
            string logMsg = "Logging trade with open position data: positionID=" + IntegerToString(positionID) + ", symbol=" + tradeData.symbol + ", tradeType=" + tradeData.tradeType;
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, logMsg);
        }
        LogTrade(tradeData);
    }
}

void PositionTracker::LogTrade(TradeData &tradeData)
{
    // Sanitize strings for SQL
    string sanitizedReasonEntry = SanitizeForSQL(tradeData.reasonEntry);
    string sanitizedReasonExit = SanitizeForSQL(tradeData.reasonExit);
    string sanitizedRemarks = SanitizeForSQL(tradeData.remarks);
    string sanitizedStrategyUsed = SanitizeForSQL(tradeData.strategyUsed);

    // Prepare SQL INSERT statement including new fields
    string insertQuery = "INSERT INTO trades (EntryDate, EntryTime, ExitDate, ExitTime, Symbol, TradeType, EntryPrice, ExitPrice, "
                         "ReasonEntry, ReasonExit, ProfitLoss, Swap, Commission, ATR, WPRValue, ADXValue, "
                         "PivotPoint, Resistance1, Support1, HighVolumeLevel, LowVolumeLevel, StrategyUsed, "
                         "Duration, LotSize, Remarks) VALUES (" +
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
                         DoubleToString(tradeData.swap, 2) + "," +
                         DoubleToString(tradeData.commission, 2) + "," +
                         DoubleToString(tradeData.atr, _Digits) + "," +
                         DoubleToString(tradeData.wprValue, 2) + "," +
                         DoubleToString(tradeData.adxValue, 2) + "," +
                         DoubleToString(tradeData.pivotPoint, _Digits) + "," +
                         DoubleToString(tradeData.resistance1, _Digits) + "," +
                         DoubleToString(tradeData.support1, _Digits) + "," +
                         DoubleToString(tradeData.highVolumeLevel, _Digits) + "," +
                         DoubleToString(tradeData.lowVolumeLevel, _Digits) + "," +
                         "'" + sanitizedStrategyUsed + "'," +
                         IntegerToString(tradeData.duration) + "," +
                         DoubleToString(tradeData.lotSize, 2) + "," +
                         "'" + sanitizedRemarks + "');";

    string errorMsg;
    if (!dbManager.ExecuteSQLQuery(insertQuery, errorMsg))
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DATABASE, "Error inserting trade log to database: " + errorMsg);
    }
    else
    {
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_DATABASE, "Trade logged to database successfully.");
    }
}

void PositionTracker::HandleOpenPositionsOnDeinit()
{
    // Full implementation of HandleOpenPositionsOnDeinit method

    // Get total positions from PositionTracker
    int totalPositions = GetTotalPositions();
    for (int i = 0; i < totalPositions; i++)
    {
        OpenPositionData positionData;
        if (!GetPositionByIndex(i, positionData))
        {
            if (logManager.ShouldLog(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION))
            {
                string logMsg = "Failed to get position data at index " + IntegerToString(i);
                LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, logMsg);
            }
            continue;
        }
        ulong positionID = positionData.positionID;

        // Attempt to find the closing deal
        ulong closingDealTicket = FindClosingDealForPosition(positionID);

        if (closingDealTicket != 0)
        {
            LogClosedTrade(positionID, closingDealTicket);
        }
        else
        {
            // Manually construct TradeData and log the trade
            if (logManager.ShouldLog(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION))
            {
                string logMsg = "No closing deal found for position ID: " + IntegerToString(positionID) +
                                ". Logging as closed due to EA deinitialization.";
                LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, logMsg);
            }

            // Manually construct TradeData
            TradeData tradeData;

            tradeData.positionID = positionData.positionID;
            tradeData.entryDate = positionData.date;
            tradeData.entryTime = positionData.time;
            tradeData.entryPrice = positionData.entryPrice;
            tradeData.reasonEntry = positionData.reasonEntry;
            tradeData.lotSize = positionData.lotSize;
            tradeData.duration = (long)(TimeCurrent() - positionData.entryTime);
            tradeData.symbol = positionData.symbol;

            // Correctly set the exit price based on the trade type
            if (positionData.tradeType == "Buy")
            {
                tradeData.exitPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            }
            else
            {
                tradeData.exitPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            }
            tradeData.exitPrice = NormalizeDouble(tradeData.exitPrice, _Digits);

            tradeData.tradeType = positionData.tradeType;
            tradeData.exitDate = TimeToString(TimeCurrent(), TIME_DATE);
            tradeData.exitTime = TimeToString(TimeCurrent(), TIME_SECONDS | TIME_MINUTES);
            tradeData.atr = positionData.atr;
            tradeData.wprValue = positionData.wprValue;
            tradeData.reasonExit = "Closed due to EA deinitialization";
            tradeData.remarks = "Logged on deinitialization";

            // Retrieve swap and commission
            double swap = 0.0;
            double commission = 0.0;

            // Attempt to find the last deal associated with this position
            ulong lastDealTicket = FindLastDealForPosition(positionID);
            if (lastDealTicket != 0 && HistoryDealSelect(lastDealTicket))
            {
                swap = HistoryDealGetDouble(lastDealTicket, DEAL_SWAP);
                commission = HistoryDealGetDouble(lastDealTicket, DEAL_COMMISSION);
            }

            // Calculate profit/loss using OrderCalcProfit
            ENUM_ORDER_TYPE orderType = (tradeData.tradeType == "Buy") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
            double calculatedProfitLoss = 0.0;

            double adjustedLotSize = tradeData.lotSize;

            if (OrderCalcProfit(
                    orderType,
                    _Symbol,
                    adjustedLotSize,
                    tradeData.entryPrice,
                    tradeData.exitPrice,
                    calculatedProfitLoss))
            {
                // Adjust profit/loss
                tradeData.profitLoss = calculatedProfitLoss + swap + commission;
                tradeData.swap = swap;
                tradeData.commission = commission;
            }
            else
            {
                int errorCode = GetLastError();
                string errorDescription = ErrorDescription(errorCode);
                LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_EXECUTION, "Failed to calculate profit/loss using OrderCalcProfit. Error code: " + IntegerToString(errorCode) + ", Description: " + errorDescription);
                tradeData.profitLoss = 0.0; // Default to zero if calculation fails
                tradeData.swap = swap;
                tradeData.commission = commission;
            }

            // Log the trade
            LogTrade(tradeData);
        }
    }

    // Clear positions from PositionTracker
    ClearAllPositions();
}

void PositionTracker::CloseAllPositions()
{
    // Start timing for CloseAllPositions
    ulong startTime = GetCustomTickCount();

    int totalPositions = PositionsTotal();
    for (int i = totalPositions - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            ulong positionID = PositionGetInteger(POSITION_TICKET);
            string symbol = PositionGetString(POSITION_SYMBOL);
            long magic = PositionGetInteger(POSITION_MAGIC);

            // Close only positions with the EA's magic number
            if (magic != m_magicNumber)
                continue;

            // Close the position
            trade.SetExpertMagicNumber(m_magicNumber);
            trade.SetDeviationInPoints(m_slippage);

            bool result = trade.PositionClose(symbol);

            if (result)
            {
                if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_TRADE_MANAGEMENT))
                {
                    string logMsg = "Closed position ID " + IntegerToString(positionID) + " due to end of day.";
                    LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_MANAGEMENT, logMsg);
                }
            }
            else
            {
                if (logManager.ShouldLog(LOG_LEVEL_ERROR, LOG_CAT_TRADE_MANAGEMENT))
                {
                    string logMsg = "Failed to close position ID " + IntegerToString(positionID) +
                                    ". Error: " + trade.ResultRetcodeDescription();
                    LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_MANAGEMENT, logMsg);
                }
            }
        }
    }

    // End timing and log duration for CloseAllPositions
    ulong endTime = GetCustomTickCount();
    ulong duration = endTime - startTime;
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_PROFILING))
    {
        string logMsg = "CloseAllPositions execution time: " + IntegerToString((int)duration) + " ms.";
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_PROFILING, logMsg);
    }
}


#endif // __POSITIONTRACKER_MQH__
