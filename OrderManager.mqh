// OrderManager.mqh

#ifndef __ORDERMANAGER_MQH__
#define __ORDERMANAGER_MQH__

#include <Trade\Trade.mqh>
#include "Logger.mqh"
#include "DataStructures.mqh"
#include "GlobalVariables.mqh"
#include "Utils.mqh"  // Include Utils to access utility functions

class OrderManager
{
private:
    CTrade trade;
    int MagicNumber;
    int Slippage;

    // Add private methods if necessary
    bool CheckStopLossAndTakeProfit(ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, double entryPrice);

public:
    // Constructor without pointers
    OrderManager(int magicNumber, int slippage)
    {
        this.MagicNumber = magicNumber;
        this.Slippage = slippage;
        trade.SetExpertMagicNumber(MagicNumber);
        trade.SetDeviationInPoints(Slippage);
    }

    ~OrderManager() {}

    // Updated OpenOrder method to include errorCode and errorDescription
    bool OpenOrder(ENUM_ORDER_TYPE orderType,
                   double lotSize,
                   double entryPrice,
                   double slPrice,
                   double tpPrice,
                   string reason,
                   double atrValue,
                   double wprValue,
                   OpenPositionData &newPosition,
                   uint &errorCode,
                   string &errorDescription);

    bool CloseOrder(ulong positionID);
    bool ModifyOrder(ulong positionID, double newSL, double newTP);
};

// Implementation of CheckStopLossAndTakeProfit
bool OrderManager::CheckStopLossAndTakeProfit(ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, double entryPrice)
{
    // Implementation of the function
    double minStopLevelPoints = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (minStopLevelPoints == 0)
        minStopLevelPoints = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

    double slDistance = 0.0;
    double tpDistance = 0.0;

    if (orderType == ORDER_TYPE_BUY) {
        slDistance = (entryPrice - slPrice) / _Point;
        tpDistance = (tpPrice - entryPrice) / _Point;
    } else if (orderType == ORDER_TYPE_SELL) {
        slDistance = (slPrice - entryPrice) / _Point;
        tpDistance = (entryPrice - tpPrice) / _Point;
    }

    slDistance = MathAbs(slDistance);
    tpDistance = MathAbs(tpDistance);

    if (slDistance < minStopLevelPoints || tpDistance < minStopLevelPoints) {
        logManager.LogMessage("SL or TP too close to price. Minimum stop level: " + DoubleToString(minStopLevelPoints, _Digits), LOG_LEVEL_ERROR);
        return false;
    }

    logManager.LogMessage("SL=" + DoubleToString(slPrice, _Digits) + " and TP=" + DoubleToString(tpPrice, _Digits) + " passed validation.", LOG_LEVEL_INFO);
    return true;
}

// Updated OpenOrder method with error handling
bool OrderManager::OpenOrder(ENUM_ORDER_TYPE orderType,
                             double lotSize,
                             double entryPrice,
                             double slPrice,
                             double tpPrice,
                             string reason,
                             double atrValue,
                             double wprValue,
                             OpenPositionData &newPosition,
                             uint &errorCode,
                             string &errorDescription)
{
    // Start timing
    ulong startTime = GetCustomTickCount();

    // Initialize error code and description
    errorCode = 0;
    errorDescription = "";

    // Validate SL and TP levels before opening the position
    if (!CheckStopLossAndTakeProfit(orderType, slPrice, tpPrice, entryPrice))
    {
        // Handle invalid SL/TP
        errorCode = ERR_INVALID_STOPS;
        errorDescription = "Invalid SL/TP levels.";
        return false;
    }

    bool tradeResult = false;
    ulong entryDealTicket = 0;

    if (orderType == ORDER_TYPE_BUY)
    {
        tradeResult = trade.Buy(lotSize, NULL, entryPrice, slPrice, tpPrice, "EA Trade");
    }
    else
    {
        tradeResult = trade.Sell(lotSize, NULL, entryPrice, slPrice, tpPrice, "EA Trade");
    }

    if (tradeResult)
    {
        // Retrieve deal ticket and position ID
        entryDealTicket = trade.ResultDeal();

        ulong positionID = 0;
        if (entryDealTicket != 0)
        {
            if (HistoryDealSelect(entryDealTicket))
            {
                positionID = (ulong)HistoryDealGetInteger(entryDealTicket, DEAL_POSITION_ID);
            }
            else
            {
                errorCode = GetLastError();
                errorDescription = "Failed to select deal after trade execution.";
                logManager.LogMessage(errorDescription, LOG_LEVEL_ERROR);
                return false;
            }
        }
        else
        {
            errorCode = GetLastError();
            errorDescription = "Failed to get deal ticket after trade execution.";
            logManager.LogMessage(errorDescription, LOG_LEVEL_ERROR);
            return false;
        }

        // Populate newPosition with relevant data
        newPosition.positionID = positionID;
        newPosition.entryDealTicket = entryDealTicket;
        newPosition.symbol = _Symbol;
        newPosition.tradeType = (orderType == ORDER_TYPE_BUY) ? "Buy" : "Sell";
        newPosition.entryPrice = entryPrice;
        newPosition.entryTime = TimeCurrent();
        newPosition.atr = atrValue;
        newPosition.wprValue = wprValue;
        newPosition.lotSize = lotSize;
        newPosition.reasonEntry = reason;
        newPosition.date = TimeToString(newPosition.entryTime, TIME_DATE);
        newPosition.time = TimeToString(newPosition.entryTime, TIME_SECONDS | TIME_MINUTES);
        newPosition.currentStopLoss = slPrice;
        newPosition.takeProfitPrice = tpPrice;
        newPosition.profitLevelReached = 0;
        newPosition.trailingStopActivated = false;
        newPosition.profitLevelAtTrailingStop = 0.0;
        newPosition.isLogged = false;

        logManager.LogMessage("Order opened successfully. Position ID: " + IntegerToString((int)positionID), LOG_LEVEL_INFO);

        // End timing and log the duration
        ulong endTime = GetCustomTickCount();
        ulong duration = endTime - startTime;
        logManager.LogMessage("OpenOrder execution time: " + IntegerToString((int)duration) + " ms.", LOG_LEVEL_INFO, LOG_CAT_PROFILING);

        return true;
    }
    else
    {
        // Handle trade failure
        errorCode = trade.ResultRetcode();
        errorDescription = trade.ResultRetcodeDescription();
        logManager.LogMessage("Trade Order Failed: " + errorDescription, LOG_LEVEL_ERROR);

        // End timing and log the duration
        ulong endTime = GetCustomTickCount();
        ulong duration = endTime - startTime;
        logManager.LogMessage("OpenOrder execution time: " + IntegerToString((int)duration) + " ms.", LOG_LEVEL_INFO, LOG_CAT_PROFILING);

        return false;
    }
}

#endif // __ORDERMANAGER_MQH__
