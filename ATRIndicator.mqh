// ATRIndicator.mqh
#ifndef __ATRINDICATOR_MQH__
#define __ATRINDICATOR_MQH__

#include "IndicatorBase.mqh"
#include "GlobalDefinitions.mqh"  // Include global definitions (contains LOG_MESSAGE macro and logging levels)
#include "LogManager.mqh"         // Include LogManager

extern CLogManager logManager;    // Declare logManager as external

class ATRIndicator : public IndicatorBase
{
private:
    int m_period;

public:
    ATRIndicator(string symbol, ENUM_TIMEFRAMES timeframe, int period)
        : IndicatorBase(symbol, timeframe), m_period(period)
    {
    }

    virtual bool Initialize()
    {
        m_handle = iATR(m_symbol, m_timeframe, m_period);
        if (m_handle == INVALID_HANDLE)
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to create ATR indicator handle.");
            return false;
        }
        return true;
    }

    virtual double GetValue(int shift = 0)
    {
        if (m_handle == INVALID_HANDLE)
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "ATR indicator handle is invalid.");
            return 0.0;
        }

        double value[1];
        if (CopyBuffer(m_handle, 0, shift, 1, value) <= 0)
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to get ATR value.");
            return 0.0;
        }
        return value[0];
    }
};

#endif // __ATRINDICATOR_MQH__