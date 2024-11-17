// AnalyseManager.mqh

#ifndef __ANALYSEMANAGER_MQH__
#define __ANALYSEMANAGER_MQH__

#include "GlobalDefinitions.mqh"
#include "LogDefinitions.mqh"
#include "LogManager.mqh"
#include "Utils.mqh"

// Externally defined variables and instances
extern CLogManager logManager;

class AnalyseManager
{
private:
    // Input parameters
    double atrStopLossMultiplierHighVolatility;
    double atrStopLossMultiplierLowVolatility;
    double RiskToRewardRatio;
    double HighRisk;
    double LowRisk;
    bool isHighVolatility;

    // Private methods
    void LogSLTPValidation(double sl, double tp, double minStopLevel, ENUM_ORDER_TYPE orderType);
    void LogError(string message, int errorCode = -1, bool includeErrorDescription = true);

public:
    // Constructor
    AnalyseManager(double atrSLMultiplierHighVol, double atrSLMultiplierLowVol, double riskToRewardRatio,
                   double highRisk, double lowRisk, bool highVolatility)
    {
        atrStopLossMultiplierHighVolatility = atrSLMultiplierHighVol;
        atrStopLossMultiplierLowVolatility = atrSLMultiplierLowVol;
        RiskToRewardRatio = riskToRewardRatio;
        HighRisk = highRisk;
        LowRisk = lowRisk;
        isHighVolatility = highVolatility;
    }

    // Methods
    bool CalculateSLTP(double atr, double &stopLossPoints, double &takeProfitPoints);
    double CalculateLotSize(double stopLossPoints, double riskPercentage);
    bool CheckStopLossAndTakeProfit(ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, double entryPrice);

    // Getters and setters for isHighVolatility
    void SetHighVolatility(bool highVolatility) { isHighVolatility = highVolatility; }
    bool GetHighVolatility() { return isHighVolatility; }

    // Getters for input parameters
    double GetATRSLMultiplierHighVolatility() { return atrStopLossMultiplierHighVolatility; }
    double GetATRSLMultiplierLowVolatility() { return atrStopLossMultiplierLowVolatility; }
    double GetRiskToRewardRatio() { return RiskToRewardRatio; }
    double GetHighRisk() { return HighRisk; }
    double GetLowRisk() { return LowRisk; }
};

//+------------------------------------------------------------------+
//| AnalyseManager Method Implementations                            |
//+------------------------------------------------------------------+

bool AnalyseManager::CalculateSLTP(double atr, double &stopLossPoints, double &takeProfitPoints)
{
    double riskToRewardRatio = RiskToRewardRatio;

    // Step 1: Set Stop Loss based on ATR and volatility
    if (isHighVolatility)
    {
        stopLossPoints = (atr * atrStopLossMultiplierHighVolatility) / _Point;  // SL for high volatility
    }
    else
    {
        stopLossPoints = (atr * atrStopLossMultiplierLowVolatility) / _Point;  // SL for low volatility
    }

    // Step 2: Calculate Take Profit using the Risk-to-Reward ratio
    takeProfitPoints = stopLossPoints * riskToRewardRatio;

    // Log the calculated SL/TP values
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_SLTP_VALUES))
    {
        string logMsg = "SL Points=" + DoubleToString(stopLossPoints, _Digits) + ", TP Points=" + DoubleToString(takeProfitPoints, _Digits);
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_SLTP_VALUES, logMsg);
    }

    // Step 3: Validate SL/TP against broker's minimum stop level
    double minStopLevelPoints = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (minStopLevelPoints == 0)
    {
        minStopLevelPoints = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
    }

    // Adjust SL/TP if needed
    if (stopLossPoints < minStopLevelPoints)
    {
        LogSLTPValidation(stopLossPoints, takeProfitPoints, minStopLevelPoints, ORDER_TYPE_BUY);  // Assuming ORDER_TYPE_BUY for logging
        LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_SLTP_VALUES, "Stop Loss is less than the minimum stop level, adjusting: " + DoubleToString(stopLossPoints, _Digits) + " to " + DoubleToString(minStopLevelPoints, _Digits));
        stopLossPoints = minStopLevelPoints;  // Adjust to meet broker's minimum stop level

        // Recalculate Take Profit based on the new Stop Loss
        takeProfitPoints = stopLossPoints * riskToRewardRatio;
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_SLTP_VALUES, "Adjusted TP based on new SL: " + DoubleToString(takeProfitPoints, _Digits));
    }

    return true;
}

double AnalyseManager::CalculateLotSize(double stopLossPoints, double riskPercentage)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * riskPercentage / 100.0;

    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

    // Calculate the value per point per lot
    double pointValuePerLot = tickValue / tickSize;

    // Calculate lot size
    double lotSize = riskAmount / (stopLossPoints * _Point * pointValuePerLot);

    // Adjust for lot step and min/max volume
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

    // Round down to nearest lot step
    lotSize = MathFloor(lotSize / lotStep) * lotStep;

    // Ensure lot size is within allowed limits
    lotSize = MathMax(minLot, MathMin(lotSize, maxLot));

    // Log risk management calculations
    LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_RISK_MANAGEMENT, "Risk Percentage: " + DoubleToString(riskPercentage, 2) + "%, Calculated Lot Size: " + DoubleToString(lotSize, 2));
    return lotSize;
}

bool AnalyseManager::CheckStopLossAndTakeProfit(ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, double entryPrice)
{
    double minStopLevelPoints = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (minStopLevelPoints == 0)
        minStopLevelPoints = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

    double slDistance = 0.0;
    double tpDistance = 0.0;

    if (orderType == ORDER_TYPE_BUY)
    {
        slDistance = (entryPrice - slPrice) / _Point;
        tpDistance = (tpPrice - entryPrice) / _Point;
    }
    else if (orderType == ORDER_TYPE_SELL)
    {
        slDistance = (slPrice - entryPrice) / _Point;
        tpDistance = (entryPrice - tpPrice) / _Point;
    }

    slDistance = MathAbs(slDistance);
    tpDistance = MathAbs(tpDistance);

    if (slDistance < minStopLevelPoints || tpDistance < minStopLevelPoints)
    {
        LogSLTPValidation(slPrice, tpPrice, minStopLevelPoints, orderType);  // Log SL/TP values if validation fails
        LogError("SL or TP too close to price. Minimum stop level: " + DoubleToString(minStopLevelPoints, _Digits));
        return false;
    }

    if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_SLTP_VALUES))
    {
        string logMsg = "SL=" + DoubleToString(slPrice, _Digits) + ", TP=" + DoubleToString(tpPrice, _Digits) + " passed validation.";
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_SLTP_VALUES, logMsg);
    }

    return true;
}

void AnalyseManager::LogSLTPValidation(double sl, double tp, double minStopLevel, ENUM_ORDER_TYPE orderType)
{
    if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_SLTP_VALUES))
    {
        string orderTypeStr = (orderType == ORDER_TYPE_BUY) ? "Buy" : "Sell";
        string logMsg = orderTypeStr + " Order - SL=" + DoubleToString(sl, _Digits) + ", TP=" + DoubleToString(tp, _Digits) + ", Min Stop Level: " + DoubleToString(minStopLevel, _Digits);
        LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_SLTP_VALUES, logMsg);
    }
}

void AnalyseManager::LogError(string message, int errorCode, bool includeErrorDescription)
{
    if (errorCode == -1)
    {
        errorCode = GetLastError();
        ResetLastError();
    }

    string errorDescription = includeErrorDescription ? ErrorDescription(errorCode) : "";
    string fullMessage = message + " - Error Code: " + IntegerToString(errorCode) + ", Description: " + errorDescription;

    // Aggregate the error instead of immediate logging
    logManager.AggregateError(errorCode, fullMessage);
}

#endif // __ANALYSEMANAGER_MQH__
