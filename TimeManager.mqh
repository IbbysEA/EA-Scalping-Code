// TimeManager.mqh

#ifndef __TIMEMANAGER_MQH__
#define __TIMEMANAGER_MQH__

#include "GlobalVariables.mqh"  // Include to access global 'logManager'
#include "PositionTracker.mqh"  // Include to access PositionTracker

class TimeManager
{
private:
    // Member variables
    int m_cooldownTime;
    int m_maxTradesPerDay;
    int m_closeTradesHour;
    int m_closeTradesMinute;
    int m_tradingStartHour;
    int m_tradingEndHour;
    bool m_CloseTradesBeforeEndOfDay;

    datetime m_lastTradeTime;
    datetime m_lastTradeDay;
    int      dailyTradeCount;

public:
    // Default Constructor
    TimeManager()
    {
        // Initialize member variables with default values
        m_cooldownTime       = 0;
        m_maxTradesPerDay    = 0;
        m_closeTradesHour    = 0;
        m_closeTradesMinute  = 0;
        m_tradingStartHour   = 0;
        m_tradingEndHour     = 0;
        m_CloseTradesBeforeEndOfDay = false;

        m_lastTradeTime = 0;
        m_lastTradeDay  = 0;
        dailyTradeCount = 0;
    }

    // Initialization method
    void Init(int cooldownTimeInput, int maxTradesPerDayInput, int closeTradesHourInput, int closeTradesMinuteInput,
              int tradingStartHourInput, int tradingEndHourInput, bool CloseTradesBeforeEndOfDayInput)
    {
        m_cooldownTime       = cooldownTimeInput;
        m_maxTradesPerDay    = maxTradesPerDayInput;
        m_closeTradesHour    = closeTradesHourInput;
        m_closeTradesMinute  = closeTradesMinuteInput;
        m_tradingStartHour   = tradingStartHourInput;
        m_tradingEndHour     = tradingEndHourInput;
        m_CloseTradesBeforeEndOfDay = CloseTradesBeforeEndOfDayInput;

        m_lastTradeTime = 0;
        m_lastTradeDay  = 0;
        dailyTradeCount = 0;
    }

    // Methods

    // Check if the cooldown period is over with timing and profiling
    bool IsCooldownPeriodOver()
    {
        // Start timing
        ulong startTime = GetCustomTickCount();

        datetime currentTime = TimeCurrent();
        bool isOver = ((currentTime - m_lastTradeTime) >= m_cooldownTime);

        // End timing and log the duration
        ulong endTime = GetCustomTickCount();
        ulong duration = endTime - startTime;
        logManager.LogMessage("IsCooldownPeriodOver execution time: " + IntegerToString((int)duration) + " ms.", LOG_LEVEL_DEBUG, LOG_CAT_PROFILING);

        return isOver;
    }

    // Check and reset daily trade count if a new day has started
    void CheckAndResetDailyTradeCount()
    {
        datetime currentDay = (datetime)(int)(TimeCurrent() / 86400) * 86400;
        if (currentDay != m_lastTradeDay)
        {
            m_lastTradeDay = currentDay;
            dailyTradeCount = 0;
            logManager.LogMessage("Daily trade count reset for new day.", LOG_LEVEL_INFO, LOG_CAT_TRADE_LIMIT);
        }
    }

    // Record a trade execution and update the last trade time and daily trade count
    void RecordTradeExecution(bool successful)
    {
        m_lastTradeTime = TimeCurrent();
        if (successful)
        {
            dailyTradeCount++;
            logManager.LogMessage("Trade executed. Updated daily trade count: " + IntegerToString(dailyTradeCount), LOG_LEVEL_INFO, LOG_CAT_TRADE_EXECUTION);
        }
    }

    // Check if the maximum number of trades per day has been reached
    bool IsMaxTradesReached()
    {
        bool maxReached = dailyTradeCount >= m_maxTradesPerDay;
        if (maxReached)
        {
            logManager.LogMessage("Maximum trades per day reached.", LOG_LEVEL_WARNING, LOG_CAT_TRADE_LIMIT);
        }
        return maxReached;
    }

    // Determine if trades should be closed before the end of the day
    bool ShouldCloseTradesBeforeEndOfDay()
    {
        datetime currentTime = TimeCurrent();
        MqlDateTime timeStruct;
        TimeToStruct(currentTime, timeStruct);

        if (timeStruct.hour > m_closeTradesHour || (timeStruct.hour == m_closeTradesHour && timeStruct.min >= m_closeTradesMinute))
            return true;
        return false;
    }

    // Check if it's a new trading day
    bool IsNewTradingDay()
    {
        datetime currentDay = (datetime)(int)(TimeCurrent() / 86400) * 86400;
        if (currentDay != m_lastTradeDay)
        {
            m_lastTradeDay = currentDay;
            dailyTradeCount = 0;
            logManager.LogMessage("New trading day detected.", LOG_LEVEL_INFO, LOG_CAT_TRADE_LIMIT);
            return true;
        }
        return false;
    }

    // Check if current time is within trading hours
    bool IsWithinTradingHours()
    {
        datetime currentTime = TimeCurrent();
        MqlDateTime timeStruct;
        TimeToStruct(currentTime, timeStruct);

        // Exclude weekends (Saturday and Sunday)
        if (timeStruct.day_of_week == 0 || timeStruct.day_of_week == 6)
            return false;

        // Check if current hour is within trading hours
        if (timeStruct.hour < m_tradingStartHour || timeStruct.hour > m_tradingEndHour)
            return false;

        return true;
    }

    // Reset daily trade count
    void ResetDailyTradeCount()
    {
        dailyTradeCount = 0;
        logManager.LogMessage("Daily trade count reset manually.", LOG_LEVEL_INFO, LOG_CAT_TRADE_LIMIT);
    }

    // Get the daily trade count
    int GetDailyTradeCount()
    {
        return dailyTradeCount;
    }

    // OnTimer method
    void OnTimer(PositionTracker &posTracker)
    {
        // Close trades before end of day to avoid swaps
        if (m_CloseTradesBeforeEndOfDay && ShouldCloseTradesBeforeEndOfDay())
        {
            logManager.LogMessage("End of day detected on timer. Closing all positions to avoid swaps.", LOG_LEVEL_INFO, LOG_CAT_TRADE_MANAGEMENT);
            posTracker.CloseAllPositions();
            return; // Skip further processing if positions are closed
        }

        // Flush logs to database
        logManager.FlushLogsToDatabase();

        // Do not flush aggregated errors here
    }
};

#endif // __TIMEMANAGER_MQH__
