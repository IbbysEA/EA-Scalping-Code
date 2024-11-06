// TimeManager.mqh
#ifndef __TIMEMANAGER_MQH__
#define __TIMEMANAGER_MQH__

class TimeManager {
public:
    datetime lastTradeTime;  // To track the last trade execution time
    int cooldownTime;        // Cooldown period in seconds
    int maxTradesPerDay;
    int dailyTradeCount;
    int lastTradeDay;
    int closeTradesHour;
    int closeTradesMinute;

    // Constructor
    TimeManager(int cooldown, int maxTrades, int closeHour, int closeMinute);

    // Check if the cooldown period has passed
    bool IsCooldownPeriodOver();

    // Reset daily trade count if a new day has started
    void CheckAndResetDailyTradeCount();

    // Increment the trade count and update last trade time
    void RecordTradeExecution();

    // Check if the maximum number of trades per day has been reached
    bool IsMaxTradesReached();

    // Check if it's time to close trades before end of day
    bool ShouldCloseTradesBeforeEndOfDay();

    // Check if a new trading day has started
    bool IsNewTradingDay();

    // Check if within trading hours
    bool IsWithinTradingHours();
};

#endif // __TIMEMANAGER_MQH__

// Implementations of methods
// Place this after the #endif or in a separate implementation file if preferred

// Constructor
TimeManager::TimeManager(int cooldown, int maxTrades, int closeHour, int closeMinute)
    : cooldownTime(cooldown), maxTradesPerDay(maxTrades),
      closeTradesHour(closeHour), closeTradesMinute(closeMinute) {
    lastTradeTime = 0;
    dailyTradeCount = 0;
    lastTradeDay = -1;
}

// Check if the cooldown period has passed
bool TimeManager::IsCooldownPeriodOver() {
    return (TimeCurrent() - lastTradeTime >= cooldownTime);
}

// Reset daily trade count if a new day has started
void TimeManager::CheckAndResetDailyTradeCount() {
    MqlDateTime currentTimeStruct;
    TimeToStruct(TimeCurrent(), currentTimeStruct);
    int currentDay = currentTimeStruct.day;

    if (currentDay != lastTradeDay) {
        dailyTradeCount = 0;
        lastTradeDay = currentDay;
    }
}

// Increment the trade count and update last trade time
void TimeManager::RecordTradeExecution() {
    dailyTradeCount++;
    lastTradeTime = TimeCurrent();
}

// Check if the maximum number of trades per day has been reached
bool TimeManager::IsMaxTradesReached() {
    return dailyTradeCount >= maxTradesPerDay;
}

// Check if it's time to close trades before end of day
bool TimeManager::ShouldCloseTradesBeforeEndOfDay() {
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    return (timeStruct.hour > closeTradesHour ||
           (timeStruct.hour == closeTradesHour && timeStruct.min >= closeTradesMinute));
}

// Check if a new trading day has started
bool TimeManager::IsNewTradingDay() {
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    return (timeStruct.day != lastTradeDay);
}

// Check if within trading hours
bool TimeManager::IsWithinTradingHours() {
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);

    // Exclude weekends
    if (timeStruct.day_of_week == 0 || timeStruct.day_of_week == 6)
        return false;

    return true;
}
