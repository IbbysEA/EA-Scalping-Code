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

    // Variables for tick volume filtering
    bool enableTickVolumeFilter;
    int tickVolumePeriods;
    double tickVolumeMultiplier;
    ENUM_TIMEFRAMES tickVolumeTimeframe;

public:
    // Constructor
    VolatilityManager(double threshold,
                      bool enableTickVolumeFilterParam,
                      int tickVolumePeriodsParam,
                      double tickVolumeMultiplierParam,
                      ENUM_TIMEFRAMES tickVolumeTimeframeParam)
    {
        atrVolatilityThreshold = threshold;
        isHighVolatility = false;

        // Initialize tick volume parameters
        enableTickVolumeFilter = enableTickVolumeFilterParam;
        tickVolumePeriods = tickVolumePeriodsParam;
        tickVolumeMultiplier = tickVolumeMultiplierParam;
        tickVolumeTimeframe = tickVolumeTimeframeParam;
    }

    // Setters and Getters
    void SetATRVolatilityThreshold(double threshold) { atrVolatilityThreshold = threshold; }
    double GetATRVolatilityThreshold() const { return atrVolatilityThreshold; }
    bool IsHighVolatility() const { return isHighVolatility; }

    void SetTickVolumeParameters(bool enableFilter, int periods, double multiplier, ENUM_TIMEFRAMES timeframe)
    {
        enableTickVolumeFilter = enableFilter;
        tickVolumePeriods = periods;
        tickVolumeMultiplier = multiplier;
        tickVolumeTimeframe = timeframe;
    }

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

    // IsTickVolumeIncreasing method
    bool IsTickVolumeIncreasing()
    {
        if (!enableTickVolumeFilter)
        {
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_VOLUME, "Tick Volume Filter is disabled.");
            return true; // If the filter is disabled, always return true
        }

        int periods = tickVolumePeriods;
        long volumes[]; // Array to store tick volumes
        int copied = CopyTickVolume(_Symbol, tickVolumeTimeframe, 0, periods + 1, volumes);

        if (copied <= periods)
        {
            LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_VOLUME, "Failed to copy tick volume data or insufficient data.");
            return false;
        }

        // Current period's volume is volumes[0], previous volumes are volumes[1..periods]

        // Calculate the average volume of previous periods
        long avgVolume = 0;
        for (int i = 1; i <= periods; i++)
        {
            avgVolume += volumes[i];
        }
        avgVolume /= periods;

        // Calculate threshold
        double threshold = avgVolume * tickVolumeMultiplier;

        // Debug log for tick volume data
        if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_VOLUME))
        {
            string logMsg = "Current Volume: " + IntegerToString(volumes[0]) +
                            ", Average Volume: " + IntegerToString(avgVolume) +
                            ", Threshold: " + DoubleToString(threshold, 2);
            LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_VOLUME, logMsg);
        }

        // Return true if current volume is greater than threshold
        if (volumes[0] > threshold)
        {
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_VOLUME, "Tick volume is increasing.");
            return true;
        }
        else
        {
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_VOLUME, "Tick volume is not increasing.");
            return false;
        }
    }
};

#endif // __VOLATILITYMANAGER_MQH__
