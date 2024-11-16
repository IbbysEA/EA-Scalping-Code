// GlobalVariables.mqh
#ifndef __GLOBALVARIABLES_MQH__
#define __GLOBALVARIABLES_MQH__

#include "LogDefinitions.mqh"
#include "LogManager.mqh"      // Include before DatabaseManager.mqh
#include "DatabaseManager.mqh"

// Declare global instances
extern CLogManager logManager;
extern CDatabaseManager dbManager;

#endif // __GLOBALVARIABLES_MQH__
