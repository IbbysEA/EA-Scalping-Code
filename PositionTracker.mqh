// PositionTracker.mqh
#ifndef __POSITIONTRACKER_MQH__
#define __POSITIONTRACKER_MQH__

#include "DataStructures.mqh"
#include "Logger.mqh"
#include "LogManager.mqh"
#include "GlobalVariables.mqh"

class PositionTracker
{
private:
    OpenPositionData positions[];

public:
    PositionTracker()
    {
    }

    ~PositionTracker() {}

    void AddPosition(const OpenPositionData &positionData);
    void RemovePositionByIndex(int index);
    int FindPositionIndex(ulong positionID);
    bool GetPositionData(ulong positionID, OpenPositionData &outPositionData);
    void UpdatePositionData(ulong positionID, const OpenPositionData &positionData);
    int GetTotalPositions();
    bool GetPositionByIndex(int index, OpenPositionData &outPositionData);
    void ClearAllPositions();
};

// Implementation of PositionTracker methods

void PositionTracker::AddPosition(const OpenPositionData &positionData)
{
    int size = ArraySize(positions);
    ArrayResize(positions, size + 1);
    positions[size] = positionData;
    logManager.LogMessage("Position added to tracker. Position ID: " + IntegerToString(positionData.positionID), LOG_LEVEL_DEBUG);
}

void PositionTracker::RemovePositionByIndex(int index)
{
    int size = ArraySize(positions);
    if (index >= 0 && index < size)
    {
        for (int i = index; i < size - 1; i++)
        {
            positions[i] = positions[i + 1];
        }
        ArrayResize(positions, size - 1);
        logManager.LogMessage("Position removed from tracker at index: " + IntegerToString(index), LOG_LEVEL_DEBUG);
    }
}

int PositionTracker::FindPositionIndex(ulong positionID)
{
    int size = ArraySize(positions);
    for (int i = 0; i < size; i++)
    {
        if (positions[i].positionID == positionID)
        {
            return i;
        }
    }
    return -1;
}

bool PositionTracker::GetPositionData(ulong positionID, OpenPositionData &outPositionData)
{
    int index = FindPositionIndex(positionID);
    if (index != -1)
    {
        outPositionData = positions[index];
        return true;
    }
    return false;
}

void PositionTracker::UpdatePositionData(ulong positionID, const OpenPositionData &updatedData)
{
    int index = FindPositionIndex(positionID);
    if (index != -1)
    {
        positions[index] = updatedData;
        logManager.LogMessage("Position data updated for Position ID: " + IntegerToString(positionID), LOG_LEVEL_DEBUG);
    }
}

int PositionTracker::GetTotalPositions()
{
    return ArraySize(positions);
}

bool PositionTracker::GetPositionByIndex(int index, OpenPositionData &outPositionData)
{
    if (index >= 0 && index < ArraySize(positions))
    {
        outPositionData = positions[index];
        return true;
    }
    return false;
}

void PositionTracker::ClearAllPositions()
{
    ArrayResize(positions, 0);
    logManager.LogMessage("All positions cleared from PositionTracker.", LOG_LEVEL_INFO);
}

#endif // __POSITIONTRACKER_MQH__
