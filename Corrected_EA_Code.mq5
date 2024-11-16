
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
#include "LogDefinitions.mqh"    // Include before other log headers
#include "GlobalVariables.mqh"   // Include after LogDefinitions.mqh
#include "Logger.mqh"
#include "LogManager.mqh"
#include "DatabaseManager.mqh"
#include "Utils.mqh"
#include "TimeManager.mqh"
#include "IndicatorManager.mqh"
#include "DataStructures.mqh"
#include "PositionTracker.mqh"
#include "TrailingStopManager.mqh"
#include "GlobalDefinitions.mqh"
#include "LogFormatter.mqh"
#include "OrderManager.mqh" // Include OrderManager

// Declare global instances
CDatabaseManager dbManager;
CLogManager logManager;

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
PositionTracker positionTracker;
TrailingStopManager trailingStopManager;
TimeManager timeManager; // Declare TimeManager as an instance

// At the top of your EA's main file
input bool EnableDebugLogging = false; // Set to true to enable debug logging

// Input parameters for other settings
input double HighRisk = 5.0;     // High risk percentage
input double LowRisk = 0.7;      // Low risk percentage
input int MagicNumber = 987654321;  // Magic number for trades
input int Slippage = 10;         // Slippage for trades

// Declare OrderManager with parameters
OrderManager orderManager(MagicNumber, Slippage); // Initialize OrderManager with magicNumber and slippage

// --- Input parameters for each indicator's timeframe
input ENUM_TIMEFRAMES ATRTimeframe = PERIOD_M1;     // Timeframe for ATR
input ENUM_TIMEFRAMES WPRTimeframe = PERIOD_M1;     // Timeframe for Williams %R
input ENUM_TIMEFRAMES TickVolumeTimeframe = PERIOD_M1;  // Timeframe for tick volume
input ENUM_TIMEFRAMES VolumeProfileTimeframe = PERIOD_M1; // Timeframe for Volume Profile
input int VolumeProfilePeriod = 20;                     // Look-back period for Volume Profile

//--- Input parameters for Trailing Stop ---
input bool EnableTrailingStop = true;               // Toggle to enable or disable Trailing Stop
// input double TrailingStopATRMultiplier = 2.0;       // **Increased Multiplier** for ATR to set trailing stop distance
// input int TrailingStopATRPeriod = 14;               // ATR period for Trailing Stop calculation
// input double TrailingStopMinDistance = 10.0;        // Minimum trailing stop distance in points

//--- ATR variables
input int atrPeriod = 14;        // ATR period (adjustable in input)
input double atrMinThreshold = 0.0001;   // Minimum ATR value for trading (adjustable in input)

//--- Williams %R Input parameters
input int WPR_Period = 14;       // Period for Williams %R
input int WPR_Overbought = -20;  // Overbought level
input int WPR_Oversold = -80;    // Oversold level

double wprValueGlobal = 0.0;     // Global variable to store Williams %R value

bool tradeExecuted = false; // Initialize trade execution flag

//--- Adjust stop-loss multiplier for low volatility
input double atrStopLossMultiplierHighVolatility = 3.0;   // Higher SL multiplier for high volatility
input double atrStopLossMultiplierLowVolatility = 2.0;    // SL multiplier for low volatility

//--- Volatility parameters
input double atrVolatilityThreshold = 0.0008; // Threshold to determine volatility
bool isHighVolatility = false;
bool wasHighVolatility = false;

//--- Cooldown parameters
input int cooldownTime = 30;  // Cooldown time in seconds

//--- Input parameters for risk management
input double stopLossMultiplier = 10;   // Multiplier for the stop loss points
double minStopLossPoints;               // Minimum stop loss points variable (initialized later)

//--- Input parameters for Trailing Stop Profit Levels ---
input double ProfitLevel1 = 15.0;
input double ProfitLevel2 = 30.0;
input double ProfitLevel3 = 45.0;
input double ProfitLevel4 = 60.0;
input double ProfitLevel5 = 75.0;

input uint TimerIntervalMilliseconds = 500; // Timer interval in milliseconds

input double RiskToRewardRatio = 1.5;  // Default risk-to-reward ratio

ulong loggedPositionIDs[];

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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    LOG_MESSAGE(LOG_LEVEL_INFO, LOG_CAT_INITIALIZATION, "EA initialization started.");
    // Rest of your initialization logic ...
}
