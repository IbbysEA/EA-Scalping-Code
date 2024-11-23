// TradeManager.mqh

#ifndef __TRADEMANAGER_MQH__
#define __TRADEMANAGER_MQH__

#include "DataStructures.mqh"
#include "PositionTracker.mqh"
#include "OrderManager.mqh"
#include "IndicatorManager.mqh"
#include "RiskManager.mqh"
#include "TimeManager.mqh"
#include "TrailingStopManager.mqh"
#include "LogManager.mqh"
#include "GlobalVariables.mqh"
#include "Utils.mqh"

// Declare external instances to access global variables
extern CLogManager logManager;
extern PositionTracker positionTracker;
extern RiskManager riskManager;
extern OrderManager orderManager;
extern IndicatorManager indicatorManager;
extern TimeManager timeManager;
extern TrailingStopManager trailingStopManager;

class TradeManager
{
private:
    // Variables
    bool tradeExecuted;  // Flag to indicate if a trade has been executed
    double wprValueGlobal;

    // Input parameters
    double atrMinThreshold;
    int WPR_Overbought;
    int WPR_Oversold;

public:
    // Constructor
    TradeManager(double atrMinThresholdParam, int wprOverboughtParam, int wprOversoldParam)
    {
        tradeExecuted = false;
        wprValueGlobal = 0.0;

        atrMinThreshold = atrMinThresholdParam;
        WPR_Overbought = wprOverboughtParam;
        WPR_Oversold = wprOversoldParam;
    }

    // Methods
    void InitializeParameters();
    void ExecuteTrade(ENUM_ORDER_TYPE orderType, double atrValue, string reason, double wprValue);
    void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result);
    void CheckForClosedPositions();
    void ProcessTradingLogic();

    // Accessors for tradeExecuted
    void ResetTradeExecutedFlag() { tradeExecuted = false; }
    bool IsTradeExecuted() { return tradeExecuted; }

    // Accessors for wprValueGlobal
    double GetWPRValueGlobal() { return wprValueGlobal; }
    void SetWPRValueGlobal(double value) { wprValueGlobal = value; }

};

// Implementation of methods

void TradeManager::InitializeParameters()
{
    // Any initialization code specific to TradeManager
    tradeExecuted = false;
    wprValueGlobal = 0.0;
}

void TradeManager::ExecuteTrade(ENUM_ORDER_TYPE orderType, double atrValue, string reason, double wprValue)
{
    // Start timing for ExecuteTrade
    ulong startTime = GetCustomTickCount();

    double stopLossPoints, takeProfitPoints;

    // Use RiskManager to calculate SL/TP values
    if (!riskManager.CalculateSLTP(atrValue, stopLossPoints, takeProfitPoints))
    {
        double atrValueCurrent = indicatorManager.GetATRValue();
        string symbol = _Symbol;
        logManager.LogFailedTrade("Failed to calculate valid SL/TP", atrValueCurrent, symbol);

        // Record failed trade execution
        timeManager.RecordTradeExecution(false);
        return;
    }

    // Calculate lot size based on risk level adjusted for volatility
    double riskPercentage = riskManager.IsHighVolatility() ? riskManager.GetHighRisk() : riskManager.GetLowRisk();
    double lotSize = riskManager.CalculateLotSize(stopLossPoints, riskPercentage);

    // Get entry price based on order type
    double entryPrice = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double slPrice = 0.0, tpPrice = 0.0;

    // Calculate Stop Loss (SL) and Take Profit (TP) prices
    if (orderType == ORDER_TYPE_BUY)
    {
        slPrice = NormalizeDouble(entryPrice - stopLossPoints * _Point, _Digits);
        tpPrice = NormalizeDouble(entryPrice + takeProfitPoints * _Point, _Digits);
    }
    else if (orderType == ORDER_TYPE_SELL)
    {
        slPrice = NormalizeDouble(entryPrice + stopLossPoints * _Point, _Digits);
        tpPrice = NormalizeDouble(entryPrice - takeProfitPoints * _Point, _Digits);
    }

    // Use RiskManager to check SL/TP levels
    if (!riskManager.CheckStopLossAndTakeProfit(orderType, slPrice, tpPrice, entryPrice))
    {
        double atrValueCurrent = indicatorManager.GetATRValue();  // Get current ATR value
        string symbol = _Symbol;            // Get current symbol
        uint errorCode = 0;                 // No specific error code
        string errorDescription = "SL/TP levels do not meet broker requirements";

        logManager.LogFailedTrade("Invalid SL/TP levels", atrValueCurrent, symbol, errorCode, errorDescription);

        // Record failed trade execution
        timeManager.RecordTradeExecution(false);
        return;
    }

    // Proceed to open the position
    OpenPositionData newPosition;
    uint errorCode = 0;
    string errorDescription = "";

    bool tradeSuccess = orderManager.OpenOrder(orderType, lotSize, entryPrice, slPrice, tpPrice, reason,
                                               atrValue, wprValue, newPosition, errorCode, errorDescription);

    // Record the trade execution (successful or failed)
    timeManager.RecordTradeExecution(tradeSuccess);

    if (tradeSuccess)
    {
        positionTracker.AddPosition(newPosition);

        // Log success of the trade execution
        if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION))
        {
            string logMsg = "Trade executed successfully. Daily trade count: " + IntegerToString(timeManager.GetDailyTradeCount());
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, logMsg);
        }
        tradeExecuted = true;
    }
    else
    {
        // Log failed trade execution
        logManager.LogFailedTrade("Trade execution failed", atrValue, _Symbol, errorCode, errorDescription);
    }

    // End timing and log duration for ExecuteTrade
    ulong endTime = GetCustomTickCount();
    ulong duration = endTime - startTime;
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_PROFILING))
    {
        string logMsg = "ExecuteTrade execution time: " + IntegerToString((int)duration) + " ms.";
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_PROFILING, logMsg);
    }

    // After a critical operation
    logManager.FlushAllLogs();
}

void TradeManager::OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
    if (trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        ulong dealTicket = trans.deal;

        if (HistoryDealSelect(dealTicket))
        {
            ulong positionID = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
            ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

            if (dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
            {
                // Use PositionTracker to check if position is logged
                if (positionTracker.IsPositionLogged(positionID))
                {
                    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
                    {
                        string logMsg = "Position ID " + IntegerToString(positionID) + " has already been logged. Skipping.";
                        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, logMsg);
                    }
                    return;
                }

                if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION))
                {
                    string logMsg = "Deal " + IntegerToString(dealTicket) + " is a closing deal for position " + IntegerToString(positionID);
                    LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, logMsg);
                }

                // Use PositionTracker to log the closed trade
                positionTracker.LogClosedTrade(positionID, dealTicket);

                int index = positionTracker.FindPositionIndex(positionID);
                if (index != -1)
                {
                    positionTracker.RemovePositionByIndex(index);

                    // Remove trailing stop line
                    trailingStopManager.RemoveTrailingStop(positionID);
                }
            }
        }
    }
}

void TradeManager::CheckForClosedPositions()
{
    // Ensure the history is up to date
    HistorySelect(0, TimeCurrent());

    int totalPositions = positionTracker.GetTotalPositions();
    int i = 0;
    while (i < totalPositions)
    {
        OpenPositionData positionData;
        if (!positionTracker.GetPositionByIndex(i, positionData))
        {
            // Log failed position data retrieval
            if (logManager.ShouldLog(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION))
            {
                string logMsg = "Failed to get position data at index " + IntegerToString(i);
                LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, logMsg);
            }
            i++;
            continue;
        }
        ulong positionID = positionData.positionID;

        // Check if the position is still open
        if (!PositionSelectByTicket(positionID))
        {
            // Position is no longer open; it has been closed
            if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
            {
                string logMsg = "Position " + IntegerToString(positionID) + " is closed. Attempting to find closing deal.";
                LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, logMsg);
            }

            // Use PositionTracker to check if position is logged
            if (positionTracker.IsPositionLogged(positionID))
            {
                LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, "Position ID " + IntegerToString(positionID) + " has already been logged. Skipping.");
                // Remove from PositionTracker
                positionTracker.RemovePositionByIndex(i);

                // Remove trailing stop line
                trailingStopManager.RemoveTrailingStop(positionID);

                totalPositions = positionTracker.GetTotalPositions(); // Update total positions
                continue;
            }

            // Use PositionTracker to find the closing deal
            ulong closingDealTicket = positionTracker.FindClosingDealForPosition(positionID);

            if (closingDealTicket != 0)
            {
                // Use PositionTracker to log the trade
                positionTracker.LogClosedTrade(positionID, closingDealTicket);

                // Remove from PositionTracker
                positionTracker.RemovePositionByIndex(i);

                // Remove trailing stop line
                trailingStopManager.RemoveTrailingStop(positionID);

                totalPositions = positionTracker.GetTotalPositions(); // Update total positions

                // After removing from PositionTracker
                if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
                {
                    string logMsg = "Removed position from PositionTracker: positionID=" + IntegerToString(positionID);
                    LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, logMsg);
                }
                // Do not increment i, as the array has shrunk
                continue;
            }
            else
            {
                // Log when closing deal not found
                if (logManager.ShouldLog(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION))
                {
                    string logMsg = "Closing deal not found for position ID: " + IntegerToString(positionID);
                    LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, logMsg);
                }
                i++; // Increment i to check the next position
            }
        }
        else
        {
            // Log when position is still open
            if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
            {
                string logMsg = "Position " + IntegerToString(positionID) + " is still open.";
                LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, logMsg);
            }
            i++; // Only increment if no removal
        }
        totalPositions = positionTracker.GetTotalPositions(); // Update total positions
    }
}

void TradeManager::ProcessTradingLogic()
{
    // Skip trading if ATR is below minimum threshold
    double atrValue = indicatorManager.GetATRValue();
    if (atrValue < atrMinThreshold)
    {
        LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_ATR, "ATR below minimum threshold. No trade will be placed. ATR: " + DoubleToString(atrValue, _Digits));
        return;
    }

    // Use RiskManager to check volatility and set volatility state
    riskManager.CheckVolatility(atrValue);
    riskManager.LogVolatilityState(atrValue);

    // Log ATR and Volatility
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_ATR))
    {
        string logMsg = "ATR=" + DoubleToString(atrValue, _Digits) +
                        ", Volatility=" + (riskManager.IsHighVolatility() ? "High" : "Low");
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_ATR, logMsg);
    }

    // Ensure trades are processed within trading hours
    if (!timeManager.IsWithinTradingHours())
    {
        LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, "Outside trading hours.");
        return;
    }

    // Fetch Williams %R value for current bar
    double wprValue = indicatorManager.GetWPRValue();
    if (wprValue == 0.0)
    {
        // Error already logged inside GetWPRValue()
        return;
    }

    wprValueGlobal = wprValue;

    // Log Williams %R Value
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
    {
        string logMsg = "Williams %R Value: " + DoubleToString(wprValueGlobal, 2);
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, logMsg);
    }

    // Declare variables
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool buySignal = false, sellSignal = false;

    // Fetch high and low volume levels from Volume Profile Indicator via IndicatorManager
    double highVolumeLevel = indicatorManager.GetHighVolumeLevel();
    double lowVolumeLevel = indicatorManager.GetLowVolumeLevel();
    if (highVolumeLevel == 0.0 || lowVolumeLevel == 0.0)
    {
        LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, "Failed to retrieve volume profile data for support/resistance levels.");
        return;
    }

    // Log Volume Profile Levels
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_ATR))
    {
        string logMsg = "High Volume Level: " + DoubleToString(highVolumeLevel, _Digits) + ", Low Volume Level: " + DoubleToString(lowVolumeLevel, _Digits);
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_ATR, logMsg);
    }

    // Conditions for buy and sell signals based on Volume Profile levels and trend direction
    int trendDirection = indicatorManager.GetTrendDirection();

    // Log the trend direction
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
    {
        string trendStr = (trendDirection == 1) ? "UP" : (trendDirection == -1) ? "DOWN" : "NEUTRAL";
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, "Trend is " + trendStr + ".");
    }

    if (wprValueGlobal <= WPR_Oversold && currentPrice <= lowVolumeLevel * 1.002 && trendDirection == 1)
    {
        buySignal = true;
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, "Buy Signal with Volume Profile support and uptrend alignment!");
    }

    if (wprValueGlobal >= WPR_Overbought && currentPrice >= highVolumeLevel * 0.998 && trendDirection == -1)
    {
        sellSignal = true;
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, "Sell Signal with Volume Profile resistance and downtrend alignment!");
    }

    // No signal detected; log and exit
    if (!buySignal && !sellSignal)
    {
        if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION))
        {
            LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_TRADE_EXECUTION, "No buy or sell signal triggered on this bar.");
        }
        return;
    }

    // Check if tick volume is increasing
    bool tickVolumeIncreasing = riskManager.IsTickVolumeIncreasing();

    // Execute Buy Trade if conditions are met
    if (buySignal && tickVolumeIncreasing)
    {
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, "Executing Buy trade based on ATR, Williams %R, Volume Profile support, and trend alignment.");
        ExecuteTrade(ORDER_TYPE_BUY, atrValue, "ATR, WPR, Volume Profile, and Trend", wprValueGlobal);
        tradeExecuted = true; // Set flag to indicate trade has been executed
    }
    else if (buySignal)
    {
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, "Buy signal detected but tick volume is not increasing. Skipping trade.");
    }
    else if (sellSignal && tickVolumeIncreasing)
    {
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, "Executing Sell trade based on ATR, Williams %R, Volume Profile resistance, and trend alignment.");
        ExecuteTrade(ORDER_TYPE_SELL, atrValue, "ATR, WPR, Volume Profile, and Trend", wprValueGlobal);
        tradeExecuted = true; // Set flag to indicate trade has been executed
    }
    else if (sellSignal)
    {
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION, "Sell signal detected but tick volume is not increasing. Skipping trade.");
    }
}

#endif // __TRADEMANAGER_MQH__
