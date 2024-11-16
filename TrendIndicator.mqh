// TrendIndicator.mqh
#ifndef __TRENDINDICATOR_MQH__
#define __TRENDINDICATOR_MQH__

#include "IndicatorBase.mqh"
#include "GlobalDefinitions.mqh"  // Include global definitions
#include "LogManager.mqh"         // Include LogManager

extern CLogManager logManager;    // Declare logManager as external

class TrendIndicator : public IndicatorBase
{
private:
    int            m_maPeriod;
    ENUM_MA_METHOD m_maMethod;
    int            m_appliedPrice;

public:
    TrendIndicator(string symbol, ENUM_TIMEFRAMES timeframe, int maPeriod, ENUM_MA_METHOD maMethod, int appliedPrice = PRICE_CLOSE)
        : IndicatorBase(symbol, timeframe), m_maPeriod(maPeriod), m_maMethod(maMethod), m_appliedPrice(appliedPrice)
    {
    }

    virtual bool Initialize()
    {
        m_handle = iMA(m_symbol, m_timeframe, m_maPeriod, 0, m_maMethod, m_appliedPrice);
        if (m_handle == INVALID_HANDLE)
        {
            // Critical error, replace Print with LOG_MESSAGE
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to create MA indicator handle for trend detection.");
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
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_INDICATORS, "Failed to get MA value for trend detection.");
            return 0.0;
        }
        return value[0];
    }

    // Method to determine trend direction
    int GetTrendDirection(int shift = 1)
    {
        double maValue = GetValue(shift);
        double closePrice = iClose(m_symbol, m_timeframe, shift);

        if (closePrice > maValue)
            return 1; // Uptrend
        else if (closePrice < maValue)
            return -1; // Downtrend
        else
            return 0; // Neutral
    }
};

#endif // __TRENDINDICATOR_MQH__
