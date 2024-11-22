//+------------------------------------------------------------------+
//|                             Your EA Name                         |
//|                           Your Name or Info                      |
//+------------------------------------------------------------------+
#property copyright "Your Name or Info"
#property version   "1.00"
#property strict

// Include statements
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include "DatabaseImports.mqh"
#include "LogDefinitions.mqh"
#include "GlobalVariables.mqh"  // Include this to declare global variables
#include "Logger.mqh"
#include "LogManager.mqh"
#include "DatabaseManager.mqh"
#include "Utils.mqh"
#include "TimeManager.mqh"
#include "DataStructures.mqh"
#include "IndicatorManager.mqh"
#include "TrailingStopManager.mqh"
#include "GlobalDefinitions.mqh"
#include "LogFormatter.mqh"
#include "OrderManager.mqh"
#include "AnalyseManager.mqh"
#include "RiskManager.mqh"
#include "VolatilityManager.mqh"
#include "InitialisationManager.mqh"  // Include the InitialisationManager
#include "TradeManager.mqh"           // Include the TradeManager

// Define global instances (definitions)
CLogManager logManager;     // Define the global logManager
CDatabaseManager dbManager; // Define the global dbManager

// Input parameters for logging
input LogLevelEnum LogLevel = LOG_LEVEL_INFO;
input uint LogCategories = LOG_CAT_ALL;  // Default to all categories
input bool EnableConsoleLogging = true;
input bool EnableDatabaseLogging = true;
input bool EnableFileLogging = false;
input string LogFilePath = "EA_Log.txt";

// Global variables
CTrade trade;
IndicatorManager indicatorManager;
TrailingStopManager trailingStopManager;
TimeManager timeManager; // Declare TimeManager as an instance
InitialisationManager initManager; // Declare InitialisationManager

// Input parameters for other settings
input int MagicNumber = 987654321;  // Magic number for trades
input int Slippage = 10;         // Slippage for trades

// Declare OrderManager with parameters
OrderManager orderManager(MagicNumber, Slippage); // Initialize OrderManager with magicNumber and slippage

// Declare PositionTracker with MagicNumber and Slippage
PositionTracker positionTracker(MagicNumber, Slippage);

// Input parameters for risk management
input double atrStopLossMultiplierHighVolatility = 3.0;   // Higher SL multiplier for high volatility
input double atrStopLossMultiplierLowVolatility = 2.0;    // SL multiplier for low volatility
input double RiskToRewardRatio = 1.5;  // Default risk-to-reward ratio
input double HighRisk = 5.0;     // High risk percentage
input double LowRisk = 0.7;      // Low risk percentage

// Input parameter for ATR volatility threshold
input double atrVolatilityThreshold = 0.0008; // Threshold to determine volatility

// --- Input parameters for each indicator's timeframe
input ENUM_TIMEFRAMES ATRTimeframe = PERIOD_M1;     // Timeframe for ATR
input ENUM_TIMEFRAMES WPRTimeframe = PERIOD_M1;     // Timeframe for Williams %R
input ENUM_TIMEFRAMES TickVolumeTimeframe = PERIOD_M1;  // Timeframe for tick volume
input ENUM_TIMEFRAMES PivotTimeframe = PERIOD_D1;   // Timeframe for Pivot Points
input ENUM_TIMEFRAMES VolumeProfileTimeframe = PERIOD_M1; // Timeframe for Volume Profile
input int VolumeProfilePeriod = 20;                     // Look-back period for Volume Profile

// **Added Input parameters for ADX indicator**
input ENUM_TIMEFRAMES ADXTimeframe = PERIOD_M15; // Timeframe for ADX
input int ADXPeriod = 14;                        // Period for ADX indicator

//--- Input parameters for Trailing Stop ---
input bool EnableTrailingStop = true;               // Toggle to enable or disable Trailing Stop

//--- ATR variables
input int atrPeriod = 14;        // ATR period (adjustable in input)
input double atrMinThreshold = 0.0001;   // Minimum ATR value for trading (adjustable in input)

//--- Williams %R Input parameters
input int WPR_Period = 14;       // Period for Williams %R
input int WPR_Overbought = -20;  // Overbought level
input int WPR_Oversold = -80;    // Oversold level

//--- Cooldown parameters
input int cooldownTime = 30;  // Cooldown time in seconds

//--- Input parameters for Trailing Stop Profit Levels ---
input double ProfitLevel1 = 15.0;
input double ProfitLevel2 = 30.0;
input double ProfitLevel3 = 45.0;
input double ProfitLevel4 = 60.0;
input double ProfitLevel5 = 75.0;

input uint TimerIntervalMilliseconds = 500; // Timer interval in milliseconds

//--- Input parameters for closing trades before end of day
input bool CloseTradesBeforeEndOfDay = true; // Enable closing trades before end of day
input int CloseTradesHour = 23;   // Hour to close all trades (24-hour format)
input int CloseTradesMinute = 59; // Minute to close all trades

//--- Input parameters for tick volume filtering
input int TickVolumePeriods = 5;      // Number of periods to consider for average tick volume
input double TickVolumeMultiplier = 1.0; // Multiplier for average tick volume threshold
input bool EnableTickVolumeFilter = true; // Enable or disable tick volume filtering

//--- Input parameters for trend detection ---
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H6; // Trend Detection
input int TrendMAPeriod = 50;                    // Period for moving average used in trend detection
input ENUM_MA_METHOD TrendMAMethod = MODE_SMA;   // Moving average method (SMA, EMA, etc.)

// New global variables for trade counting
input int maxTradesPerDay = 10;   // Maximum allowed trades per day

input int TradingStartHour = 0;  // Trading start hour (0-23)
input int TradingEndHour = 23;   // Trading end hour (0-23)

datetime lastBarTime = 0; // To track the last bar time for resetting tradeExecuted

// Declare instance of RiskManager after atrVolatilityThreshold is declared
RiskManager riskManager(atrStopLossMultiplierHighVolatility, atrStopLossMultiplierLowVolatility,
                        RiskToRewardRatio, HighRisk, LowRisk, atrVolatilityThreshold,
                        EnableTickVolumeFilter, TickVolumePeriods, TickVolumeMultiplier, TickVolumeTimeframe);

// Declare TradeManager
double adxThreshold = 25.0; // Set your desired ADX threshold
TradeManager tradeManager(atrMinThreshold, WPR_Overbought, WPR_Oversold, adxThreshold);


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize file directories and paths
    #ifdef TESTER
    string filesDir = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Tester\\Files";
    #else
    string filesDir = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files";
    #endif
    string dbPath = filesDir + "\\TradeLog.db";

    // Initialize TrailingStopManager profit levels
    double profitLevels[5];
    profitLevels[0] = ProfitLevel1;
    profitLevels[1] = ProfitLevel2;
    profitLevels[2] = ProfitLevel3;
    profitLevels[3] = ProfitLevel4;
    profitLevels[4] = ProfitLevel5;
    int numProfitLevels = ArraySize(profitLevels);

    // Variable to check if trading is allowed
    bool tradeAllowed = false;

    // *** Added variable to hold symbol ***
    string symbolParam = _Symbol;

    // Updated call to InitializeAll with PivotTimeframe
    bool initSuccess = initManager.InitializeAll(
        timeManager,                // tm
        indicatorManager,           // im
        trailingStopManager,        // tsm
        orderManager,               // om
        positionTracker,            // pt
        riskManager,                // rm
        // Input parameters
        LogLevel,                   // logLevelParam
        LogCategories,              // logCategoriesParam
        EnableConsoleLogging,       // enableConsoleLoggingParam
        EnableDatabaseLogging,      // enableDatabaseLoggingParam
        EnableFileLogging,          // enableFileLoggingParam
        LogFilePath,                // logFilePathParam
        filesDir,                   // filesDirParam
        dbPath,                     // dbPathParam
        cooldownTime,               // cooldownTimeParam
        maxTradesPerDay,            // maxTradesPerDayParam
        CloseTradesHour,            // closeTradesHourParam
        CloseTradesMinute,          // closeTradesMinuteParam
        TradingStartHour,           // tradingStartHourParam
        TradingEndHour,             // tradingEndHourParam
        CloseTradesBeforeEndOfDay,  // closeTradesBeforeEndOfDayParam
        profitLevels,               // profitLevelsParam
        numProfitLevels,            // numProfitLevelsParam
        ATRTimeframe,               // atrTimeframeParam
        atrPeriod,                  // atrPeriodParam
        WPRTimeframe,               // wprTimeframeParam
        WPR_Period,                 // wprPeriodParam
        TrendTimeframe,             // trendTimeframeParam
        TrendMAPeriod,              // trendMAPeriodParam
        TrendMAMethod,              // trendMAMethodParam
        VolumeProfileTimeframe,     // volumeProfileTimeframeParam
        VolumeProfilePeriod,        // volumeProfilePeriodParam
        ADXTimeframe,               // adxTimeframeParam
        ADXPeriod,                  // adxPeriodParam
        PivotTimeframe,             // pivotTimeframeParam (Added)
        TimerIntervalMilliseconds,  // timerIntervalMillisecondsParam
        symbolParam,                // symbolParam (pass variable instead of expression)
        tradeAllowed                // tradeAllowedParam
    );

    if (!initSuccess)
    {
        return INIT_FAILED;
    }

    // Initialize other parameters
    lastBarTime = 0;
    tradeManager.InitializeParameters();

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    initManager.DeinitializeAll(
        positionTracker,
        reason
    );
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Start timing
    ulong startTime = GetCustomTickCount();

    // Close trades before end of day
    if (CloseTradesBeforeEndOfDay && timeManager.ShouldCloseTradesBeforeEndOfDay())
    {
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_TRADE_MANAGEMENT, "End of day detected. Closing all positions.");
        positionTracker.CloseAllPositions();

        // End timing and log duration
        ulong endTime = GetCustomTickCount();
        ulong duration = endTime - startTime;
        if (logManager.ShouldLog(LOG_LEVEL_DEBUG, LOG_CAT_PROFILING))
        {
            string logMsg = "OnTick execution time: " + IntegerToString((int)duration) + " ms.";
            LOG_MESSAGE(LOG_LEVEL_DEBUG, LOG_CAT_PROFILING, logMsg);
        }
        return; // Skip further processing if positions are closed
    }

    // Reset daily trade count if a new day has started
    timeManager.CheckAndResetDailyTradeCount();

    // Check if daily trade limit has been reached
    if (timeManager.IsMaxTradesReached())
    {
        LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_LIMIT, "Daily trade limit reached. No further trades will be executed today.");

        // End timing and log duration
        ulong endTime = GetCustomTickCount();
        ulong duration = endTime - startTime;
        if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_PROFILING))
        {
            string logMsg = "OnTick execution time: " + IntegerToString((int)duration) + " ms.";
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_PROFILING, logMsg);
        }
        return;
    }

    // Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0); // Get the time of the current bar
    if (currentBarTime != lastBarTime)
    {
        tradeManager.ResetTradeExecutedFlag();  // Reset tradeExecuted flag for the new bar
        lastBarTime = currentBarTime;
    }

    // Check if cooldown period has passed using TimeManager
    if (!timeManager.IsCooldownPeriodOver())
    {
        LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_COOLDOWN, "Cooldown time is active. Waiting before placing new trades.");

        // End timing and log duration
        ulong endTime = GetCustomTickCount();
        ulong duration = endTime - startTime;
        if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_PROFILING))
        {
            string logMsg = "OnTick execution time: " + IntegerToString((int)duration) + " ms.";
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_PROFILING, logMsg);
        }
        return;
    }

    // Prevent repeated trade execution if tradeExecuted is set
    if (tradeManager.IsTradeExecuted())
    {
        LOG_MESSAGE(LOG_LEVEL_WARNING, LOG_CAT_TRADE_EXECUTION, "Trade already executed on this bar, skipping further trade execution.");

        // End timing and log duration
        ulong endTime = GetCustomTickCount();
        ulong duration = endTime - startTime;
        if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_PROFILING))
        {
            string logMsg = "OnTick execution time: " + IntegerToString((int)duration) + " ms.";
            LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_PROFILING, logMsg);
        }
        return;
    }

    // Manage trailing stops
    if (EnableTrailingStop)
    {
        trailingStopManager.ManageAllTrailingStops(positionTracker);
    }

    // Always check for closed positions
    tradeManager.CheckForClosedPositions();

    // Process trading logic
    tradeManager.ProcessTradingLogic();

    // End timing and log duration
    ulong endTime = GetCustomTickCount();
    ulong duration = endTime - startTime;
    if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_PROFILING))
    {
        string logMsg = "OnTick execution time: " + IntegerToString((int)duration) + " ms.";
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_PROFILING, logMsg);
    }
}

//+------------------------------------------------------------------+
//| OnTimer event function                                           |
//+------------------------------------------------------------------+
void OnTimer()
{
    timeManager.OnTimer(positionTracker);
}

//+------------------------------------------------------------------+
//| OnTradeTransaction Event Handler                                 |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
    tradeManager.OnTradeTransaction(trans, request, result);
}
