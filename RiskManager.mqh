//+------------------------------------------------------------------+
//|                          RiskManager.mqh                         |
//|             Manages risk and volatility-related logic            |
//+------------------------------------------------------------------+
#ifndef __RISKMANAGER_MQH__
#define __RISKMANAGER_MQH__

#include "AnalyseManager.mqh"
#include "VolatilityManager.mqh"

class RiskManager
{
private:
    AnalyseManager analyseManager;      // Instance of AnalyseManager
    VolatilityManager volatilityManager; // Instance of VolatilityManager

public:
    // Constructor
    RiskManager(double atrSLMultiplierHighVol, double atrSLMultiplierLowVol,
                double riskToRewardRatio, double highRisk, double lowRisk,
                double atrVolatilityThresholdParam,
                bool enableTickVolumeFilterParam,
                int tickVolumePeriodsParam,
                double tickVolumeMultiplierParam,
                ENUM_TIMEFRAMES tickVolumeTimeframeParam)
        : analyseManager(atrSLMultiplierHighVol, atrSLMultiplierLowVol, riskToRewardRatio, highRisk, lowRisk, false),
          volatilityManager(atrVolatilityThresholdParam,
                            enableTickVolumeFilterParam,
                            tickVolumePeriodsParam,
                            tickVolumeMultiplierParam,
                            tickVolumeTimeframeParam) {}

    // Expose AnalyseManager methods
    bool CalculateSLTP(double atr, double &stopLossPoints, double &takeProfitPoints)
    {
        return analyseManager.CalculateSLTP(atr, stopLossPoints, takeProfitPoints);
    }

    double CalculateLotSize(double stopLossPoints, double riskPercentage)
    {
        return analyseManager.CalculateLotSize(stopLossPoints, riskPercentage);
    }

    bool CheckStopLossAndTakeProfit(ENUM_ORDER_TYPE orderType, double slPrice, double tpPrice, double entryPrice)
    {
        return analyseManager.CheckStopLossAndTakeProfit(orderType, slPrice, tpPrice, entryPrice);
    }

    // Expose VolatilityManager methods
    bool CheckVolatility(double atrValue)
    {
        bool currentHighVolatility = volatilityManager.CheckVolatility(atrValue);
        // Update AnalyseManager's volatility state
        analyseManager.SetHighVolatility(currentHighVolatility);
        return currentHighVolatility;
    }

    void LogVolatilityState(double atrValue)
    {
        volatilityManager.LogVolatilityState(atrValue);
    }

    bool IsTickVolumeIncreasing()
    {
        return volatilityManager.IsTickVolumeIncreasing();
    }

    // Getters for risk percentages
    double GetHighRisk() { return analyseManager.GetHighRisk(); }
    double GetLowRisk() { return analyseManager.GetLowRisk(); }

    // Getter for volatility state
    bool IsHighVolatility() { return volatilityManager.IsHighVolatility(); }
};

#endif // __RISKMANAGER_MQH__
