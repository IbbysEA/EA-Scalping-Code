// InitialisationManager.mqh

#ifndef __INITIALISATIONMANAGER_MQH__
#define __INITIALISATIONMANAGER_MQH__

#include "GlobalDefinitions.mqh"  // Include to access global constants
#include "GlobalVariables.mqh"    // Include to access global 'dbManager' and 'logManager'
#include "TimeManager.mqh"
#include "IndicatorManager.mqh"
#include "TrailingStopManager.mqh"
#include "OrderManager.mqh"
#include "PositionTracker.mqh"
#include "RiskManager.mqh"

// Remove #pragma once as per your request

class InitialisationManager
{
public:
    // Constructor
    InitialisationManager()
    {
        // Constructor code if needed
    }

    // Initialization method
    bool InitializeAll(
        // Pass references to instances to be initialized
        TimeManager &tm,
        IndicatorManager &im,
        TrailingStopManager &tsm,
        OrderManager &om,
        PositionTracker &pt,
        RiskManager &rm,
        // Input parameters
        LogLevelEnum logLevelParam,
        uint logCategoriesParam,
        bool enableConsoleLoggingParam,
        bool enableDatabaseLoggingParam,
        bool enableFileLoggingParam,
        string logFilePathParam,
        string filesDirParam,
        string dbPathParam,
        int cooldownTimeParam,
        int maxTradesPerDayParam,
        int closeTradesHourParam,
        int closeTradesMinuteParam,
        int tradingStartHourParam,
        int tradingEndHourParam,
        bool closeTradesBeforeEndOfDayParam,
        double &profitLevelsParam[],  // Arrays must be passed by reference
        int numProfitLevelsParam,
        ENUM_TIMEFRAMES atrTimeframeParam,
        int atrPeriodParam,
        ENUM_TIMEFRAMES wprTimeframeParam,
        int wprPeriodParam,
        ENUM_TIMEFRAMES trendTimeframeParam,
        int trendMAPeriodParam,
        ENUM_MA_METHOD trendMAMethodParam,
        ENUM_TIMEFRAMES volumeProfileTimeframeParam,
        int volumeProfilePeriodParam,
        ENUM_TIMEFRAMES adxTimeframeParam,
        int adxPeriodParam,
        ENUM_TIMEFRAMES pivotTimeframeParam,
        uint timerIntervalMillisecondsParam,
        string symbolParam,    // Passed by reference
        bool &tradeAllowedParam
    );

    // Deinitialization method remains unchanged
    void DeinitializeAll(
        PositionTracker &pt,
        const int reason
    );
};

//+------------------------------------------------------------------+
//| Implementation of InitializeAll                                  |
//+------------------------------------------------------------------+
bool InitialisationManager::InitializeAll(
    // Parameters as above
    TimeManager &tm,
    IndicatorManager &im,
    TrailingStopManager &tsm,
    OrderManager &om,
    PositionTracker &pt,
    RiskManager &rm,
    // Input parameters
    LogLevelEnum logLevelParam,
    uint logCategoriesParam,
    bool enableConsoleLoggingParam,
    bool enableDatabaseLoggingParam,
    bool enableFileLoggingParam,
    string logFilePathParam,
    string filesDirParam,
    string dbPathParam,
    int cooldownTimeParam,
    int maxTradesPerDayParam,
    int closeTradesHourParam,
    int closeTradesMinuteParam,
    int tradingStartHourParam,
    int tradingEndHourParam,
    bool closeTradesBeforeEndOfDayParam,
    double &profitLevelsParam[],
    int numProfitLevelsParam,
    ENUM_TIMEFRAMES atrTimeframeParam,
    int atrPeriodParam,
    ENUM_TIMEFRAMES wprTimeframeParam,
    int wprPeriodParam,
    ENUM_TIMEFRAMES trendTimeframeParam,
    int trendMAPeriodParam,
    ENUM_MA_METHOD trendMAMethodParam,
    ENUM_TIMEFRAMES volumeProfileTimeframeParam,
    int volumeProfilePeriodParam,
    ENUM_TIMEFRAMES adxTimeframeParam,
    int adxPeriodParam,
    ENUM_TIMEFRAMES pivotTimeframeParam,
    uint timerIntervalMillisecondsParam,
    string symbolParam,    // Passed by reference
    bool &tradeAllowedParam
)
{
    // Use global 'dbManager' and 'logManager' directly

    // Initialize dbManager
    dbManager.Init(dbPathParam);

    if (!dbManager.OpenDatabaseConnection())
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DATABASE, "Failed to open database connection.");
        return false;
    }

    if (!dbManager.CreateTables())
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DATABASE, "Failed to create database tables.");
        return false;
    }

    // Initialize logManager
    logManager.Init(logLevelParam,
                    logCategoriesParam,
                    enableConsoleLoggingParam,
                    enableDatabaseLoggingParam,
                    enableFileLoggingParam,
                    logFilePathParam,
                    /* bufferFlushSize */ 10,
                    /* enableDebugLogging */ false);

    // Initialize Indicator Manager
    if (!im.InitializeIndicators(
            symbolParam,
            // ATR parameters
            atrTimeframeParam, atrPeriodParam,
            // WPR parameters
            wprTimeframeParam, wprPeriodParam,
            // Trend Indicator parameters
            trendTimeframeParam, trendMAPeriodParam, trendMAMethodParam,
            // Volume Profile Indicator parameters
            volumeProfileTimeframeParam, volumeProfilePeriodParam,
            // ADX parameters
            adxTimeframeParam, adxPeriodParam,
            // Pivot Point parameters
            pivotTimeframeParam
        ))
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_AGGREGATED_ERRORS, "Failed to initialize indicators.");
        return false;
    }

    // Check if automated trading is allowed
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_AGGREGATED_ERRORS, "Automated trading is disabled. Please enable automated trading.");
        return false;
    }
    tradeAllowedParam = true;

    // Ensure the symbol is selected and data is available
    if (!SymbolSelect(symbolParam, true))
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_AGGREGATED_ERRORS, "Failed to select symbol " + symbolParam);
        return false;
    }

    // Initialize timer for regular updates
    EventSetMillisecondTimer((int)timerIntervalMillisecondsParam);

    // Initialize logging and database
    LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_INITIALIZATION, "Initializing EA and preparing log file...");

    // Initialize TimeManager with parameters
    tm.Init(cooldownTimeParam, maxTradesPerDayParam, closeTradesHourParam, closeTradesMinuteParam, tradingStartHourParam, tradingEndHourParam, closeTradesBeforeEndOfDayParam);

    LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_INITIALIZATION, "TimeManager initialized with cooldown, max trades, close time, and CloseTradesBeforeEndOfDay.");

    // Initialize TrailingStopManager
    tsm.Initialize(profitLevelsParam, numProfitLevelsParam);

    // Log successful initialization
    LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_INITIALIZATION, "EA initialized successfully.");

    return true;
}

//+------------------------------------------------------------------+
//| Implementation of DeinitializeAll                                |
//+------------------------------------------------------------------+
void InitialisationManager::DeinitializeAll(
    PositionTracker &pt,
    const int reason
)
{
    // Use global 'dbManager' and 'logManager' directly

    // Flush remaining logs to ensure all data is written to the database
    logManager.FlushLogsToDatabase();

    // Flush any remaining aggregated errors
    logManager.FlushAggregatedErrors();

    if (logManager.ShouldLog(LOG_LEVEL_INFO, LOG_CAT_DEINITIALIZATION))
    {
        string logMsg = "Expert deinitialized with reason: " + IntegerToString(reason);
        LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_DEINITIALIZATION, logMsg);
    }

    // Handle open positions
    pt.HandleOpenPositionsOnDeinit();

    // Export trade log to CSV and open it using DatabaseManager's function
    string localfilesDir = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files";
    string csvFilePath = localfilesDir + "\\TradeLog.csv";
    if (!dbManager.ExportTradeLogsToCSV(csvFilePath))
    {
        LOG_MESSAGE(LOG_LEVEL_ERROR, LOG_CAT_DATABASE, "Failed to export trade logs to CSV.");
    }

    // Close the database if it's open
    dbManager.CloseDatabaseConnection();

    // Remove the timer
    EventKillTimer();
}

#endif // __INITIALISATIONMANAGER_MQH__
