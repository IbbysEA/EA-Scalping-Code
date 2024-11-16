// WPRIndicator.mqh
#ifndef __WPRINDICATOR_MQH__
#define __WPRINDICATOR_MQH__

#include "IndicatorBase.mqh"
#include "GlobalDefinitions.mqh"  // Include global definitions
#include "LogManager.mqh"         // Include LogManager

extern CLogManager logManager;    // Declare logManager as external

class WPRIndicator : public IndicatorBase
{
private:
    int m_period;

public:
    WPRIndicator(string symbol, ENUM_TIMEFRAMES timeframe, int period)
        : IndicatorBase(symbol, timeframe), m_period(period)
    {
    }

    virtual bool Initialize()
    {
        m_handle = iWPR(m_symbol, m_timeframe, m_period);
        if (m_handle == INVALID_HANDLE)
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to create WPR indicator handle.");
            return false;
        }
        return true;
    }

    virtual double GetValue(int shift = 0)
    {
        if (m_handle == INVALID_HANDLE)
        {
            // Handle invalid handle without logging
            return 0.0;
        }

        double value[1];
        if (CopyBuffer(m_handle, 0, shift, 1, value) <= 0)
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to get WPR value.");
            return 0.0;
        }
        return value[0];
    }
};

#endif // __WPRINDICATOR_MQH__
