// IndicatorBase.mqh
#ifndef __INDICATORBASE_MQH__
#define __INDICATORBASE_MQH__

class IndicatorBase
{
protected:
    string      m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int         m_handle;

public:
    // Constructor
    IndicatorBase(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        m_symbol    = symbol;
        m_timeframe = timeframe;
        m_handle    = INVALID_HANDLE;
    }

    // Destructor
    virtual ~IndicatorBase()
    {
        if (m_handle != INVALID_HANDLE)
        {
            IndicatorRelease(m_handle);
            m_handle = INVALID_HANDLE;
        }
    }

    // Virtual methods to be implemented by subclasses
    virtual bool Initialize() = 0;
    virtual double GetValue(int shift = 0) = 0;
};

#endif // __INDICATORBASE_MQH__
