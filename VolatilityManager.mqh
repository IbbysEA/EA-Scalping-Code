//+------------------------------------------------------------------+
//|                     VolatilityManager.mqh                        |
//|             Handles ATR-based volatility checks                  |
//+------------------------------------------------------------------+
#ifndef __VOLATILITYMANAGER_MQH__
#define __VOLATILITYMANAGER_MQH__

#include "GlobalDefinitions.mqh"
#include "LogDefinitions.mqh"
#include "Logger.mqh"
#include "LogManager.mqh"

// External log manager
extern CLogManager logManager;

class VolatilityManager
{
private:
    double atrVolatilityThreshold;  // ATR threshold for determining high volatility
    bool isHighVolatility;          // Current volatility state

public:
    // Constructor
    VolatilityManager(double threshold)
    {
        atrVolatilityThreshold = threshold;
        isHighVolatility = false;
    }

    // Setters and Getters
    void SetATRVolatilityThreshold(double threshold) { atrVolatilityThreshold = threshold; }
    double GetATRVolatilityThreshold() const { return atrVolatilityThreshold; }
    bool IsHighVolatility() const { return isHighVolatility; }

    // Core Methods
    bool CheckVolatility(double atrValue)
    {
        bool currentHighVolatility = (atrValue >= atrVolatilityThreshold);

        if (currentHighVolatility != isHighVolatility)
        {
            // Log volatility state change
            string logMsg = currentHighVolatility ? "Volatility changed to HIGH." : "Volatility changed to LOW.";
            if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_ATR))
                LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_ATR, logMsg);

            isHighVolatility = currentHighVolatility;
        }

        return isHighVolatility;
    }

    void LogVolatilityState(double atrValue)
    {
        string logMsg = "ATR: " + DoubleToString(atrValue, _Digits) +
                        ", Volatility: " + (isHighVolatility ? "HIGH" : "LOW");
        if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_ATR))
            LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_ATR, logMsg);
    }
};

#endif // __VOLATILITYMANAGER_MQH__
