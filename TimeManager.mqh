#ifndef __TIMEMANAGER_MQH__
#define __TIMEMANAGER_MQH__

class TimeManager {
public:
    datetime lastTradeTime;  
    int cooldownTime;
    int maxTradesPerDay;
    int dailyTradeCount;
    int lastTradeDay;
    int closeTradesHour;
    int closeTradesMinute;
    int startHour;
    int endHour;

    // Constructor with start and end hour parameters
    TimeManager(int cooldown, int maxTrades, int closeHour, int closeMinute, int startHr, int endHr);

    bool IsCooldownPeriodOver();
    void CheckAndResetDailyTradeCount();
    void RecordTradeExecution(bool tradeSuccessful);
    void RecordTradeExecution(); // Original function
    bool IsMaxTradesReached();
    bool ShouldCloseTradesBeforeEndOfDay();
    bool IsNewTradingDay();
    bool IsWithinTradingHours();
};

// Constructor implementation with parameters
TimeManager::TimeManager(int cooldown, int maxTrades, int closeHour, int closeMinute, int startHr, int endHr)
    : cooldownTime(cooldown), maxTradesPerDay(maxTrades), closeTradesHour(closeHour), closeTradesMinute(closeMinute),
      startHour(startHr), endHour(endHr) {
    lastTradeTime = 0;
    dailyTradeCount = 0;
    lastTradeDay = -1;
}

// Check if the cooldown period has passed
bool TimeManager::IsCooldownPeriodOver() {
    datetime currentTime = TimeCurrent();
    return (currentTime - lastTradeTime >= cooldownTime);
}

// Reset daily trade count if a new day has started
void TimeManager::CheckAndResetDailyTradeCount() {
    MqlDateTime currentTimeStruct;
    TimeToStruct(TimeCurrent(), currentTimeStruct);
    int currentDay = currentTimeStruct.day;

    if (currentDay != lastTradeDay) {
        Print("New trading day detected. Resetting daily trade count.");
        dailyTradeCount = 0;  // Reset the daily trade count only at the start of a new day
        lastTradeDay = currentDay;
    }
}

// Record trade execution only if it's a new trade
void TimeManager::RecordTradeExecution(bool tradeSuccessful)
{
    if (tradeSuccessful) // Increment only on successful trades
    {
        dailyTradeCount++;
        Print("Trade executed successfully. Daily trade count updated to: ", dailyTradeCount);
    }
    lastTradeTime = TimeCurrent(); // Update last trade time for cooldown tracking
}

// Original function for backward compatibility
void TimeManager::RecordTradeExecution()
{
    dailyTradeCount++;
    lastTradeTime = TimeCurrent();
    Print("Trade executed. Daily trade count updated to: ", dailyTradeCount);
}

// Check if maximum trades for the day has been reached
bool TimeManager::IsMaxTradesReached()
{
    Print("Current daily trade count: ", dailyTradeCount, ", Max trades per day allowed: ", maxTradesPerDay); // Debug message
    if (dailyTradeCount >= maxTradesPerDay)
    {
        Print("Daily trade limit reached: ", maxTradesPerDay);
        return true;
    }
    return false;
}

// Check if it is time to close trades before end of day
bool TimeManager::ShouldCloseTradesBeforeEndOfDay() {
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    return (timeStruct.hour > closeTradesHour || (timeStruct.hour == closeTradesHour && timeStruct.min >= closeTradesMinute));
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
    return (timeStruct.hour >= startHour && timeStruct.hour < endHour);
}

#endif // __TIMEMANAGER_MQH__
