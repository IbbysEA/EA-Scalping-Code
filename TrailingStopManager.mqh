// TrailingStopManager.mqh

#ifndef __TRAILINGSTOPMANAGER_MQH__
#define __TRAILINGSTOPMANAGER_MQH__

#include "DataStructures.mqh"
#include "PositionTracker.mqh"
#include "Logger.mqh"
#include "Utils.mqh"
#include <Trade\Trade.mqh>
#include "LogManager.mqh"
#include "GlobalVariables.mqh"

class TrailingStopManager
{
private:
    CTrade trade;
    double ProfitLevels[];
    int NumProfitLevels;

public:
    // Constructor
    TrailingStopManager() {}

    // Initialize method
    void Initialize(double &profitLevels[], int numLevels)
    {
        // Copy profitLevels...
        NumProfitLevels = numLevels;
        ArrayResize(ProfitLevels, NumProfitLevels);
        for (int i = 0; i < NumProfitLevels; i++)
        {
            ProfitLevels[i] = profitLevels[i];
        }
    }

    void ManageAllTrailingStops(PositionTracker &posTracker);
    void ManageTrailingStop(OpenPositionData &positionData);
    bool ModifyPositionSL(ulong positionID, double desiredSL, long tradeType, bool isAdjusted = false);
    double AdjustSLToBrokerLimits(double desiredSL, long tradeType, string symbol);
};

// Implementations
void TrailingStopManager::ManageAllTrailingStops(PositionTracker &posTracker)
{
    // Start timing
    ulong startTime = GetCustomTickCount();

    int totalPositions = posTracker.GetTotalPositions();
    OpenPositionData positionData;

    for (int i = 0; i < totalPositions; i++)
    {
        if (posTracker.GetPositionByIndex(i, positionData))
        {
            ManageTrailingStop(positionData);

            // Update the position data in PositionTracker
            posTracker.UpdatePositionData(positionData.positionID, positionData);
        }
    }

    // End timing and log the duration
    ulong endTime = GetCustomTickCount();
    ulong duration = endTime - startTime;
    logManager.LogMessage("ManageAllTrailingStops execution time: " + IntegerToString((int)duration) + " ms.", LOG_LEVEL_INFO, LOG_CAT_PROFILING);
}

void TrailingStopManager::ManageTrailingStop(OpenPositionData &positionData)
{
    ulong positionID = positionData.positionID;
    double entryPrice = positionData.entryPrice;
    double takeProfitPrice = positionData.takeProfitPrice;
    int profitLevelReached = positionData.profitLevelReached;

    // Select the position by ticket
    if (!PositionSelectByTicket(positionID))
    {
        logManager.LogMessage("Failed to select position with ID " + IntegerToString(positionID), LOG_LEVEL_ERROR, LOG_CAT_AGGREGATED_ERRORS);
        return;
    }

    long tradeType = PositionGetInteger(POSITION_TYPE);  // Buy or Sell
    double currentSL = PositionGetDouble(POSITION_SL);   // Current Stop Loss

    // Get the current price based on the position type
    string symbol = PositionGetString(POSITION_SYMBOL);
    double currentBid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double currentPriceForCalc = (tradeType == POSITION_TYPE_BUY) ? currentBid : currentAsk;

    // Retrieve point size and digits
    double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    // Calculate total profit target and current profit achieved
    double totalProfitTarget = 0.0;
    double profitAchieved = 0.0;

    if (tradeType == POSITION_TYPE_BUY)
    {
        totalProfitTarget = takeProfitPrice - entryPrice;
        if (totalProfitTarget <= 0)
        {
            logManager.LogMessage("Total profit target is zero or negative; cannot calculate profit achieved.", LOG_LEVEL_WARNING);
            return;
        }
        profitAchieved = currentPriceForCalc - entryPrice;
    }
    else if (tradeType == POSITION_TYPE_SELL)
    {
        totalProfitTarget = entryPrice - takeProfitPrice;
        if (totalProfitTarget <= 0)
        {
            logManager.LogMessage("Total profit target is zero or negative; cannot calculate profit achieved.", LOG_LEVEL_WARNING);
            return;
        }
        profitAchieved = entryPrice - currentPriceForCalc;
    }

    double currentProfitPercentage = (profitAchieved / totalProfitTarget) * 100.0;

    // Log the percentage of the profit target achieved
    logManager.LogMessage("Current profit target achieved: " + DoubleToString(currentProfitPercentage, 2) + "%", LOG_LEVEL_DEBUG);

    // Use the stored ProfitLevels
    for (int i = 0; i < NumProfitLevels; i++)
    {
        if (currentProfitPercentage >= ProfitLevels[i] && profitLevelReached < (i + 1))
        {
            double desiredSL = 0.0;

            // Move SL to lock in profits based on profit levels
            if (tradeType == POSITION_TYPE_BUY)
            {
                desiredSL = entryPrice + ((ProfitLevels[i] / 100.0) * totalProfitTarget) * 0.5; // Lock in 50% of the profit at this level
                desiredSL = MathMax(desiredSL, entryPrice); // Ensure SL is at least at entry price
                desiredSL = NormalizeDouble(desiredSL, digits);
            }
            else if (tradeType == POSITION_TYPE_SELL)
            {
                desiredSL = entryPrice - ((ProfitLevels[i] / 100.0) * totalProfitTarget) * 0.5; // Lock in 50% of the profit at this level
                desiredSL = MathMin(desiredSL, entryPrice); // Ensure SL is at least at entry price
                desiredSL = NormalizeDouble(desiredSL, digits);
            }

            logManager.LogMessage("Profit Target: " + DoubleToString(currentProfitPercentage, 2) + "% achieved, Adjusting SL to " + DoubleToString(desiredSL, digits), LOG_LEVEL_DEBUG);

            // Try to modify the SL, adjusting if necessary due to broker constraints
            if (ModifyPositionSL(positionID, desiredSL, tradeType))
            {
                positionData.currentStopLoss = desiredSL; // Update current stop loss in the position data
                positionData.profitLevelReached = i + 1; // Update profit level only if SL modification is successful

                // Set trailing stop activation
                positionData.trailingStopActivated = true;
                positionData.profitLevelAtTrailingStop = ProfitLevels[i]; // Record the profit level

                logManager.LogMessage("Successfully modified SL for position ID " + IntegerToString(positionID) + " to " + DoubleToString(desiredSL, digits), LOG_LEVEL_DEBUG);
            }
            else
            {
                // If unable to set SL to desired level, set it as close as possible
                double adjustedSL = AdjustSLToBrokerLimits(desiredSL, tradeType, symbol);
                if (MathAbs(adjustedSL - currentSL) > (pointSize * 0.1))  // Check if there is an actual change
                {
                    if (ModifyPositionSL(positionID, adjustedSL, tradeType, true))
                    {
                        positionData.currentStopLoss = adjustedSL; // Update current stop loss in the position data
                        positionData.profitLevelReached = i + 1; // Update profit level only if SL modification is successful

                        // Set trailing stop activation
                        positionData.trailingStopActivated = true;
                        positionData.profitLevelAtTrailingStop = ProfitLevels[i]; // Record the profit level

                        logManager.LogMessage("Adjusted SL for position ID " + IntegerToString(positionID) + " to closest allowed level " + DoubleToString(adjustedSL, digits), LOG_LEVEL_INFO);
                    }
                    else
                    {
                        logManager.LogMessage("Failed to modify SL for position ID " + IntegerToString(positionID) + " even after adjustment", LOG_LEVEL_WARNING);
                        // Do not update profitLevelReached so the EA can retry
                    }
                }
                else
                {
                    logManager.LogMessage("SL is already at the closest possible level. No modification made.", LOG_LEVEL_INFO);
                    // Update profitLevelReached to prevent repeated attempts
                    positionData.profitLevelReached = i + 1;
                }
            }
            break; // Only attempt once per tick
        }
    }
}

bool TrailingStopManager::ModifyPositionSL(ulong positionID, double desiredSL, long tradeType, bool isAdjusted = false)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    if (!PositionSelectByTicket(positionID))
    {
        logManager.LogMessage("ModifyPositionSL: Failed to select position ID " + IntegerToString(positionID) + ".", LOG_LEVEL_ERROR);
        return false;
    }

    string symbol = PositionGetString(POSITION_SYMBOL);
    double currentTP = PositionGetDouble(POSITION_TP);   // Preserve the current TP
    double currentPrice = (tradeType == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
    double currentSL = PositionGetDouble(POSITION_SL);   // Get the current SL

    // Get the minimum stop level in points
    double minStopLevelPoints = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (minStopLevelPoints == 0)
        minStopLevelPoints = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
    double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double minStopDistance = minStopLevelPoints * pointSize;

    double newSL = desiredSL;

    // Adjust newSL to account for the minimum stop distance
    if (tradeType == POSITION_TYPE_BUY)
    {
        double minValidSL = currentPrice - minStopDistance;
        if (newSL >= minValidSL)
        {
            if (!isAdjusted)
            {
                // Cannot set SL to desired level due to broker constraints
                return false;
            }
            else
            {
                // Already adjusted, accept the newSL
                newSL = minValidSL - (pointSize * 0.1); // Slightly more to ensure it passes
            }
        }
        if (newSL <= currentSL)
        {
            logManager.LogMessage("New SL is not better than the current SL for BUY position.", LOG_LEVEL_WARNING);
            return false;
        }
    }
    else if (tradeType == POSITION_TYPE_SELL)
    {
        double maxValidSL = currentPrice + minStopDistance;
        if (newSL <= maxValidSL)
        {
            if (!isAdjusted)
            {
                // Cannot set SL to desired level due to broker constraints
                return false;
            }
            else
            {
                // Already adjusted, accept the newSL
                newSL = maxValidSL + (pointSize * 0.1); // Slightly more to ensure it passes
            }
        }
        if (newSL >= currentSL)
        {
            logManager.LogMessage("New SL is not better than the current SL for SELL position.", LOG_LEVEL_WARNING);
            return false;
        }
    }

    // Get digits
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    // Normalize the newSL
    newSL = NormalizeDouble(newSL, digits);

    // Prepare trade request
    request.action = TRADE_ACTION_SLTP;
    request.position = positionID;
    request.symbol = symbol;
    request.sl = newSL;
    request.tp = currentTP; // Preserve the existing TP
    // If you have a MagicNumber accessible, set it here
    // request.magic = MagicNumber;

    // Send the trade request
    if (!OrderSend(request, result))
    {
        int errorCode = GetLastError();
        string errorDescription = ErrorDescription(errorCode);

        // Use StringFormat to build the error message
        string errorMsg = StringFormat("Failed to modify SL for position ID %I64d. Error Code: %d, Description: %s", positionID, errorCode, errorDescription);

        logManager.LogMessage(errorMsg, LOG_LEVEL_ERROR);
        ResetLastError();
        return false;
      }
   return true;
}
   
double TrailingStopManager::AdjustSLToBrokerLimits(double desiredSL, long tradeType, string symbol)
{
    double currentPrice = (tradeType == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);

    // Get the minimum stop level in points
    double minStopLevelPoints = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (minStopLevelPoints == 0)
        minStopLevelPoints = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
    double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double minStopDistance = minStopLevelPoints * pointSize;

    double adjustedSL = desiredSL;

    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    if (tradeType == POSITION_TYPE_BUY)
    {
        double minValidSL = currentPrice - minStopDistance;
        adjustedSL = MathMin(desiredSL, minValidSL - (pointSize * 0.1)); // Slightly more to ensure it passes
        adjustedSL = NormalizeDouble(adjustedSL, digits);
    }
    else if (tradeType == POSITION_TYPE_SELL)
    {
        double maxValidSL = currentPrice + minStopDistance;
        adjustedSL = MathMax(desiredSL, maxValidSL + (pointSize * 0.1)); // Slightly more to ensure it passes
        adjustedSL = NormalizeDouble(adjustedSL, digits);
    }

    return adjustedSL;
}

#endif // __TRAILINGSTOPMANAGER_MQH__
