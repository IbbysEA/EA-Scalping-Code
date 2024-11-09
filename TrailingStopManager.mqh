// TrailingStopManager.mqh
#ifndef __TRAILINGSTOPMANAGER_MQH__
#define __TRAILINGSTOPMANAGER_MQH__

#include "DataStructures.mqh"
#include "PositionTracker.mqh"
#include "Logger.mqh"
#include "Utils.mqh"
#include <Trade\Trade.mqh>

class TrailingStopManager
{
private:
    CTrade trade;
    double ProfitLevels[];
    int NumProfitLevels;

public:
    TrailingStopManager()
    {
        // Default constructor
    }

    ~TrailingStopManager() {}

    void Initialize(double &profitLevels[], int numLevels)
    {
        ArrayResize(ProfitLevels, numLevels);
        ArrayCopy(ProfitLevels, profitLevels);
        NumProfitLevels = numLevels;
    }

    void ManageAllTrailingStops(PositionTracker &posTracker, CLogger &log);
    void ManageTrailingStop(OpenPositionData &positionData, CLogger &log);
    bool ModifyPositionSL(ulong positionID, double desiredSL, long tradeType, CLogger &log, bool isAdjusted = false);
    double AdjustSLToBrokerLimits(double desiredSL, long tradeType, string symbol);
};

// Implementations

void TrailingStopManager::ManageAllTrailingStops(PositionTracker &posTracker, CLogger &log)
{
    int totalPositions = posTracker.GetTotalPositions();
    OpenPositionData positionData;

    for (int i = 0; i < totalPositions; i++)
    {
        if (posTracker.GetPositionByIndex(i, positionData))
        {
            ManageTrailingStop(positionData, log);

            // Update the position data in PositionTracker
            posTracker.UpdatePositionData(positionData.positionID, positionData, log);
        }
    }
}

void TrailingStopManager::ManageTrailingStop(OpenPositionData &positionData, CLogger &log)
{
    ulong positionID = positionData.positionID;
    double entryPrice = positionData.entryPrice;
    double takeProfitPrice = positionData.takeProfitPrice;
    int profitLevelReached = positionData.profitLevelReached;

    // Select the position by ticket
    if (!PositionSelectByTicket(positionID))
    {
        log.LogMessage("Failed to select position with ID " + IntegerToString(positionID), LOG_LEVEL_ERROR, LOG_CAT_ERRORS);
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
            log.LogMessage("Total profit target is zero or negative; cannot calculate profit achieved.", LOG_LEVEL_WARNING);
            return;
        }
        profitAchieved = currentPriceForCalc - entryPrice;
    }
    else if (tradeType == POSITION_TYPE_SELL)
    {
        totalProfitTarget = entryPrice - takeProfitPrice;
        if (totalProfitTarget <= 0)
        {
            log.LogMessage("Total profit target is zero or negative; cannot calculate profit achieved.", LOG_LEVEL_WARNING);
            return;
        }
        profitAchieved = entryPrice - currentPriceForCalc;
    }

    double currentProfitPercentage = (profitAchieved / totalProfitTarget) * 100.0;

    // Log the percentage of the profit target achieved
    log.LogMessage("Current profit target achieved: " + DoubleToString(currentProfitPercentage, 2) + "%", LOG_LEVEL_DEBUG);

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

            log.LogMessage("Profit Target: " + DoubleToString(currentProfitPercentage, 2) + "% achieved, Adjusting SL to " + DoubleToString(desiredSL, digits), LOG_LEVEL_DEBUG);

            // Try to modify the SL, adjusting if necessary due to broker constraints
            if (ModifyPositionSL(positionID, desiredSL, tradeType, log))
            {
                positionData.currentStopLoss = desiredSL; // Update current stop loss in the position data
                positionData.profitLevelReached = i + 1; // Update profit level only if SL modification is successful

                // Set trailing stop activation
                positionData.trailingStopActivated = true;
                positionData.profitLevelAtTrailingStop = ProfitLevels[i]; // Record the profit level

                log.LogMessage("Successfully modified SL for position ID " + IntegerToString(positionID) + " to " + DoubleToString(desiredSL, digits), LOG_LEVEL_DEBUG);
            }
            else
            {
                // If unable to set SL to desired level, set it as close as possible
                double adjustedSL = AdjustSLToBrokerLimits(desiredSL, tradeType, symbol);
                if (MathAbs(adjustedSL - currentSL) > (pointSize * 0.1))  // Check if there is an actual change
                {
                    if (ModifyPositionSL(positionID, adjustedSL, tradeType, log, true))
                    {
                        positionData.currentStopLoss = adjustedSL; // Update current stop loss in the position data
                        positionData.profitLevelReached = i + 1; // Update profit level only if SL modification is successful

                        // Set trailing stop activation
                        positionData.trailingStopActivated = true;
                        positionData.profitLevelAtTrailingStop = ProfitLevels[i]; // Record the profit level

                        log.LogMessage("Adjusted SL for position ID " + IntegerToString(positionID) + " to closest allowed level " + DoubleToString(adjustedSL, digits), LOG_LEVEL_INFO);
                    }
                    else
                    {
                        log.LogMessage("Failed to modify SL for position ID " + IntegerToString(positionID) + " even after adjustment", LOG_LEVEL_WARNING);
                        // Do not update profitLevelReached so the EA can retry
                    }
                }
                else
                {
                    log.LogMessage("SL is already at the closest possible level. No modification made.", LOG_LEVEL_INFO);
                    // Update profitLevelReached to prevent repeated attempts
                    positionData.profitLevelReached = i + 1;
                }
            }
            break; // Only attempt once per tick
        }
    }
}

bool TrailingStopManager::ModifyPositionSL(ulong positionID, double desiredSL, long tradeType, CLogger &log, bool isAdjusted)
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    if (!PositionSelectByTicket(positionID))
    {
        log.LogMessage("ModifyPositionSL: Failed to select position ID " + IntegerToString(positionID) + ".", LOG_LEVEL_ERROR);
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
            log.LogMessage("New SL is not better than the current SL for BUY position.", LOG_LEVEL_WARNING);
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
            log.LogMessage("New SL is not better than the current SL for SELL position.", LOG_LEVEL_WARNING);
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

        log.LogMessage(errorMsg, LOG_LEVEL_ERROR);
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
