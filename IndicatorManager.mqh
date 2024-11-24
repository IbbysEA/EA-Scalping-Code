// IndicatorManager.mqh

#ifndef __INDICATORMANAGER_MQH__
#define __INDICATORMANAGER_MQH__

#include "ATRIndicator.mqh"
#include "WPRIndicator.mqh"
#include "TrendIndicator.mqh"
#include "VolumeProfileIndicator.mqh"
#include "ADXIndicator.mqh"
#include "PivotPointIndicator.mqh" // Include the PivotPointIndicator
#include "GlobalDefinitions.mqh"
#include "LogManager.mqh"

extern CLogManager logManager;

class IndicatorManager
{
private:
    ATRIndicator           atrIndicator;
    WPRIndicator           wprIndicator;
    TrendIndicator         trendIndicator;
    VolumeProfileIndicator volumeProfileIndicator;
    ADXIndicator           adxIndicator;
    PivotPointIndicator    pivotPointIndicator; // Add the pivot point indicator

    bool atrInitialized;
    bool wprInitialized;
    bool trendInitialized;
    bool volumeProfileInitialized;
    bool adxInitialized;
    bool pivotPointInitialized; // Add a flag for pivot point initialization

public:
    // Constructor
    IndicatorManager() : atrIndicator("", PERIOD_CURRENT, 14),
                         wprIndicator("", PERIOD_CURRENT, 14),
                         trendIndicator("", PERIOD_CURRENT, 50, MODE_SMA),
                         volumeProfileIndicator("", PERIOD_CURRENT, 20),
                         adxIndicator("", PERIOD_CURRENT, 14),
                         pivotPointIndicator("", PERIOD_D1) // Default to daily timeframe
    {
        atrInitialized = false;
        wprInitialized = false;
        trendInitialized = false;
        volumeProfileInitialized = false;
        adxInitialized = false;
        pivotPointInitialized = false;
    }

    // Destructor
    ~IndicatorManager()
    {
        // Destructor code if needed
    }

    // Initialize all indicators
    bool InitializeIndicators(
        string symbol,    // Passed by reference
        // ATR parameters
        ENUM_TIMEFRAMES atrTimeframe, int atrPeriodParam,
        // WPR parameters
        ENUM_TIMEFRAMES wprTimeframe, int wprPeriod,
        // Trend Indicator parameters
        ENUM_TIMEFRAMES trendTimeframe, int trendMAPeriod, ENUM_MA_METHOD trendMAMethod,
        // Volume Profile Indicator parameters
        ENUM_TIMEFRAMES volumeProfileTimeframe, int volumeProfilePeriod,
        // ADX parameters
        ENUM_TIMEFRAMES adxTimeframeParam, int adxPeriodParam,
        // Pivot Point parameters
        ENUM_TIMEFRAMES pivotTimeframeParam
    )
    {
        // Initialize ATR Indicator
        atrIndicator = ATRIndicator(symbol, atrTimeframe, atrPeriodParam);
        if (!atrIndicator.Initialize())
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize ATR Indicator.");
            return false;
        }
        atrInitialized = true;

        // Initialize WPR Indicator
        wprIndicator = WPRIndicator(symbol, wprTimeframe, wprPeriod);
        if (!wprIndicator.Initialize())
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize WPR Indicator.");
            return false;
        }
        wprInitialized = true;

        // Initialize Trend Indicator
        trendIndicator = TrendIndicator(symbol, trendTimeframe, trendMAPeriod, trendMAMethod);
        if (!trendIndicator.Initialize())
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize Trend Indicator.");
            return false;
        }
        trendInitialized = true;

        // Initialize Volume Profile Indicator
        volumeProfileIndicator = VolumeProfileIndicator(symbol, volumeProfileTimeframe, volumeProfilePeriod);
        if (!volumeProfileIndicator.Initialize())
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize Volume Profile Indicator.");
            return false;
        }
        volumeProfileInitialized = true;

        // Initialize ADX Indicator
        adxIndicator = ADXIndicator(symbol, adxTimeframeParam, adxPeriodParam);
        if (!adxIndicator.Initialize())
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize ADX Indicator.");
            return false;
        }
        adxInitialized = true;

        // Initialize Pivot Point Indicator
        pivotPointIndicator = PivotPointIndicator(symbol, pivotTimeframeParam);
        if (!pivotPointIndicator.Initialize())
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize Pivot Point Indicator.");
            return false;
        }
        pivotPointInitialized = true;

        return true;
    }

    // Method to get the ATR value with checks
    double GetATRValue()
    {
        if (!atrInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_AGGREGATED_ERRORS, "ATR Indicator not initialized.");
            return 0.0;
        }
        double atrValue = atrIndicator.GetValue();
        if (!IsValidValue(atrValue))
        {
            LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_ATR, "Invalid ATR value.");
            return 0.0;
        }
        return atrValue;
    }

    // Method to get the Williams %R value
    double GetWPRValue()
    {
        if (!wprInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_AGGREGATED_ERRORS, "WPR Indicator not initialized.");
            return 0.0;
        }
        double wprValue = wprIndicator.GetValue();
        if (!IsValidValue(wprValue))
        {
            LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, "Invalid Williams %R value.");
            return 0.0;
        }
        return wprValue;
    }

    // Method to get the High Volume Level from Volume Profile
    double GetHighVolumeLevel()
    {
        if (!volumeProfileInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_EXECUTION, "Volume Profile Indicator not initialized.");
            return 0.0;
        }
        return volumeProfileIndicator.GetHighVolumeLevel();
    }

    // Method to get the Low Volume Level from Volume Profile
    double GetLowVolumeLevel()
    {
        if (!volumeProfileInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_EXECUTION, "Volume Profile Indicator not initialized.");
            return 0.0;
        }
        return volumeProfileIndicator.GetLowVolumeLevel();
    }

    // Method to get the Trend Direction
    int GetTrendDirection()
    {
        if (!trendInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_TRADE_EXECUTION, "Trend Indicator not initialized.");
            return 0; // Neutral trend if failed
        }
        return trendIndicator.GetTrendDirection();
    }

    // Method to get the ADX value
    double GetADXValue()
    {
        if (!adxInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DEV_STAGE, "ADX Indicator not initialized.");
            return 0.0;
        }
        double adxValue = adxIndicator.GetValue();
        if (!IsValidValue(adxValue))
        {
            LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_DEV_STAGE, "Invalid ADX value.");
            return 0.0;
        }
        return adxValue;
    }

    // Methods to calculate and get pivot point values
    void CalculatePivotPoints()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return;
        }
        pivotPointIndicator.CalculatePivotPoints();
    }

    double GetPivotPoint()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return 0.0;
        }
        return pivotPointIndicator.GetPivotPoint();
    }

    double GetResistance1()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return 0.0;
        }
        return pivotPointIndicator.GetResistance1();
    }

    double GetSupport1()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return 0.0;
        }
        return pivotPointIndicator.GetSupport1();
    }

    double GetResistance2()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return 0.0;
        }
        return pivotPointIndicator.GetResistance2();
    }

    double GetSupport2()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return 0.0;
        }
        return pivotPointIndicator.GetSupport2();
    }

    double GetResistance3()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return 0.0;
        }
        return pivotPointIndicator.GetResistance3();
    }

    double GetSupport3()
    {
        if (!pivotPointInitialized)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Pivot Point Indicator not initialized.");
            return 0.0;
        }
        return pivotPointIndicator.GetSupport3();
    }

    // Method to determine market condition
    int GetMarketCondition()
    {
        double adxValue = GetADXValue();
        if (adxValue == 0.0)
        {
            // Error already logged in GetADXValue()
            return MARKET_CONDITION_UNKNOWN;
        }

        const double ADX_TRENDING_THRESHOLD = 25.0;

        if (adxValue <= ADX_TRENDING_THRESHOLD)
        {
            return MARKET_CONDITION_CONSOLIDATING;
        }
        else
        {
            return MARKET_CONDITION_TRENDING;
        }
    }
};

#endif // __INDICATORMANAGER_MQH__
