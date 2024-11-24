// VolumeProfileIndicator.mqh
#ifndef __VOLUMEPROFILEINDICATOR_MQH__
#define __VOLUMEPROFILEINDICATOR_MQH__

#include "GlobalDefinitions.mqh"  // Include global definitions (contains LOG_MESSAGE macro and logging levels)
#include "LogManager.mqh"         // Include LogManager

extern CLogManager logManager;    // Declare logManager as external

class VolumeProfileIndicator
{
private:
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    int period;
    int indicatorHandle;

public:
    // Constructor
    VolumeProfileIndicator(string sym, ENUM_TIMEFRAMES tf, int per)
    {
        symbol = sym;
        timeframe = tf;
        period = per;
        indicatorHandle = INVALID_HANDLE;
    }

    // Initialize method
    bool Initialize()
    {
        indicatorHandle = iCustom(symbol, timeframe, "Volume Indicator", period);
        if (indicatorHandle == INVALID_HANDLE)
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to initialize Volume Profile Indicator.");
            return false;
        }
        return true;
    }

    // Get High Volume Level
    double GetHighVolumeLevel()
    {
        double buffer[1];
        if (CopyBuffer(indicatorHandle, 0, 0, 1, buffer) <= 0)
            return 0.0; // Less critical, leave as is
        return buffer[0];
    }

    // Get Low Volume Level
    double GetLowVolumeLevel()
    {
        double buffer[1];
        if (CopyBuffer(indicatorHandle, 1, 0, 1, buffer) <= 0)
            return 0.0; // Less critical, leave as is
        return buffer[0];
    }
};

#endif // __VOLUMEPROFILEINDICATOR_MQH__