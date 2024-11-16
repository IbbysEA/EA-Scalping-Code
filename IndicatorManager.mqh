// IndicatorManager.mqh
#ifndef __INDICATORMANAGER_MQH__
#define __INDICATORMANAGER_MQH__

#include "ATRIndicator.mqh"
#include "WPRIndicator.mqh"
#include "TrendIndicator.mqh"
#include "VolumeProfileIndicator.mqh" // Include the Volume Profile Indicator
#include "GlobalDefinitions.mqh"      // Include global definitions
#include "LogManager.mqh"             // Include LogManager

extern CLogManager logManager;        // Declare logManager as external

class IndicatorManager
{
public:
    ATRIndicator    *atrIndicator;
    WPRIndicator    *wprIndicator;
    TrendIndicator  *trendIndicator;
    VolumeProfileIndicator *volumeProfileIndicator; // Declare volumeProfileIndicator
    // Add other indicators here

    // Constructor
    IndicatorManager()
    {
        atrIndicator   = NULL;
        wprIndicator   = NULL;
        trendIndicator = NULL;
        volumeProfileIndicator = NULL; // Initialize to NULL
        // Initialize other indicators to NULL
    }

    // Destructor
    ~IndicatorManager()
    {
        if (atrIndicator != NULL)
        {
            delete atrIndicator;
            atrIndicator = NULL;
        }
        if (wprIndicator != NULL)
        {
            delete wprIndicator;
            wprIndicator = NULL;
        }
        if (trendIndicator != NULL)
        {
            delete trendIndicator;
            trendIndicator = NULL;
        }
        if (volumeProfileIndicator != NULL)
        {
            delete volumeProfileIndicator;
            volumeProfileIndicator = NULL;
        }
        // Delete other indicators
    }

    // Initialize all indicators
    bool InitializeIndicators(
        string symbol,
        // ATR parameters
        ENUM_TIMEFRAMES atrTimeframe, int atrPeriodParam,
        // WPR parameters
        ENUM_TIMEFRAMES wprTimeframe, int wprPeriod,
        // Trend Indicator parameters
        ENUM_TIMEFRAMES trendTimeframe, int trendMAPeriod, ENUM_MA_METHOD trendMAMethod,
        // Volume Profile Indicator parameters
        ENUM_TIMEFRAMES volumeProfileTimeframe, int volumeProfilePeriod
    )
    {
        // Initialize ATR Indicator
        atrIndicator = new ATRIndicator(symbol, atrTimeframe, atrPeriodParam);
        if (!atrIndicator.Initialize())
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize ATR Indicator.");
            return false;
        }

        // Initialize WPR Indicator
        wprIndicator = new WPRIndicator(symbol, wprTimeframe, wprPeriod);
        if (!wprIndicator.Initialize())
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize WPR Indicator.");
            return false;
        }

        // Initialize Trend Indicator
        trendIndicator = new TrendIndicator(symbol, trendTimeframe, trendMAPeriod, trendMAMethod);
        if (!trendIndicator.Initialize())
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize Trend Indicator.");
            return false;
        }

        // Initialize Volume Profile Indicator
        volumeProfileIndicator = new VolumeProfileIndicator(symbol, volumeProfileTimeframe, volumeProfilePeriod);
        if (!volumeProfileIndicator.Initialize())
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize Volume Profile Indicator.");
            return false;
        }

        // Initialize other indicators as needed

        return true;
    }

    // Method to get the Williams %R value
    double GetWPRValue()
    {
        if (wprIndicator == NULL)
            return EMPTY_VALUE;
        return wprIndicator.GetValue();
    }

    // Method to get the High Volume Level from Volume Profile
    double GetHighVolumeLevel()
    {
        if (volumeProfileIndicator == NULL)
            return 0.0;
        return volumeProfileIndicator.GetHighVolumeLevel();
    }

    // Method to get the Low Volume Level from Volume Profile
    double GetLowVolumeLevel()
    {
        if (volumeProfileIndicator == NULL)
            return 0.0;
        return volumeProfileIndicator.GetLowVolumeLevel();
    }
};

#endif // __INDICATORMANAGER_MQH__
