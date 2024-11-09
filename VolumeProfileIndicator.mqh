// VolumeProfileIndicator.mqh
#ifndef __VOLUMEPROFILEINDICATOR_MQH__
#define __VOLUMEPROFILEINDICATOR_MQH__

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
            Print("Failed to initialize Volume Profile Indicator");
            return false;
        }
        return true;
    }

    // Get High Volume Level
    double GetHighVolumeLevel()
    {
        double buffer[1];
        if (CopyBuffer(indicatorHandle, 0, 0, 1, buffer) <= 0)
            return 0.0;
        return buffer[0];
    }

    // Get Low Volume Level
    double GetLowVolumeLevel()
    {
        double buffer[1];
        if (CopyBuffer(indicatorHandle, 1, 0, 1, buffer) <= 0)
            return 0.0;
        return buffer[0];
    }
};

#endif // __VOLUMEPROFILEINDICATOR_MQH__
