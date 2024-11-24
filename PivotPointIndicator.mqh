// PivotPointIndicator.mqh

#ifndef __PIVOTPOINTINDICATOR_MQH__
#define __PIVOTPOINTINDICATOR_MQH__

#include "IndicatorBase.mqh"
#include "LogDefinitions.mqh"  // Include to access LOG_MESSAGE macro and logging levels
#include "GlobalDefinitions.mqh"  // Include global definitions (contains LOG_CAT_INDICATORS)
#include "LogManager.mqh"         // Include LogManager

extern CLogManager logManager;    // Declare logManager as external

class PivotPointIndicator : public IndicatorBase
{
private:
    double m_pivotPoint;
    double m_resistance1;
    double m_support1;
    double m_resistance2;
    double m_support2;
    double m_resistance3;
    double m_support3;

    ENUM_TIMEFRAMES m_pivotTimeframe;

public:
    // Constructor
    PivotPointIndicator(string symbol, ENUM_TIMEFRAMES pivotTimeframe)
        : IndicatorBase(symbol, pivotTimeframe)
    {
        m_pivotTimeframe = pivotTimeframe;
        m_pivotPoint = 0.0;
        m_resistance1 = 0.0;
        m_support1 = 0.0;
        m_resistance2 = 0.0;
        m_support2 = 0.0;
        m_resistance3 = 0.0;
        m_support3 = 0.0;
    }

    // Destructor
    virtual ~PivotPointIndicator()
    {
        // No handles to release
    }

    // Initialize method
    virtual bool Initialize()
    {
        // No indicator handle needed for pivot points
        return true;
    }

    // GetValue method (returns pivot point)
    virtual double GetValue(int shift = 0)
    {
        return m_pivotPoint;
    }

    // Calculate pivot points
    void CalculatePivotPoints()
    {
        // Get previous period's high, low, and close based on pivot timeframe
        int prevBarIndex = 1; // Previous bar
        MqlRates rates[];
        int copied = CopyRates(m_symbol, m_pivotTimeframe, prevBarIndex, 1, rates);
        if (copied <= 0)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DEV_STAGE, "Failed to retrieve previous period's data for pivot points.");
            return;
        }

        double prevHigh = rates[0].high;
        double prevLow = rates[0].low;
        double prevClose = rates[0].close;

        if (prevHigh == 0.0 || prevLow == 0.0 || prevClose == 0.0)
        {
            LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DEV_STAGE, "Invalid data in previous period's rates for pivot points.");
            return;
        }

        // Calculate pivot point
        m_pivotPoint = (prevHigh + prevLow + prevClose) / 3.0;

        // Calculate support and resistance levels
        m_resistance1 = (2.0 * m_pivotPoint) - prevLow;
        m_support1 = (2.0 * m_pivotPoint) - prevHigh;
        m_resistance2 = m_pivotPoint + (prevHigh - prevLow);
        m_support2 = m_pivotPoint - (prevHigh - prevLow);
        m_resistance3 = prevHigh + 2.0 * (m_pivotPoint - prevLow);
        m_support3 = prevLow - 2.0 * (prevHigh - m_pivotPoint);
    }

    // Getter methods
    double GetPivotPoint()   { return m_pivotPoint; }
    double GetResistance1()  { return m_resistance1; }
    double GetSupport1()     { return m_support1; }
    double GetResistance2()  { return m_resistance2; }
    double GetSupport2()     { return m_support2; }
    double GetResistance3()  { return m_resistance3; }
    double GetSupport3()     { return m_support3; }
};

#endif // __PIVOTPOINTINDICATOR_MQH__
