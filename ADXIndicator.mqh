// ADXIndicator.mqh
#ifndef __ADXINDICATOR_MQH__
#define __ADXINDICATOR_MQH__

#include "IndicatorBase.mqh"
#include "GlobalDefinitions.mqh"
#include "LogManager.mqh"

extern CLogManager logManager;

class ADXIndicator : public IndicatorBase
{
private:
    int m_period;

public:
    // Constructor
    ADXIndicator(string symbol, ENUM_TIMEFRAMES timeframe, int period) : IndicatorBase(symbol, timeframe)
    {
        m_period = period;
    }

    // Destructor
    virtual ~ADXIndicator()
    {
        // Base class destructor will handle IndicatorRelease
    }

    // Initialize the ADX indicator
    virtual bool Initialize()
    {
        m_handle = iADX(m_symbol, m_timeframe, m_period);
        if (m_handle == INVALID_HANDLE)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DEV_STAGE, "Failed to initialize ADX Indicator.");
            return false;
        }
        return true;
    }

    // Get the ADX value
    virtual double GetValue(int shift = 0)
    {
        double adxBuffer[];
        if (CopyBuffer(m_handle, 0, shift, 1, adxBuffer) <= 0)
        {
            LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_DEV_STAGE, "Failed to get ADX value.");
            return 0.0;
        }
        return adxBuffer[0];
    }
};

#endif // __ADXINDICATOR_MQH__