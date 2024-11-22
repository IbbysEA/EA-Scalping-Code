//+------------------------------------------------------------------+
//|                                                   SuperTrend.mq5 |
//|                                           Copyright 2011, FxGeek |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, FxGeek"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots 2

#property indicator_label1  "Filling"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrPaleGreen, clrLightCoral
#property indicator_style1  STYLE_SOLID, STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "SuperTrend"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGreen, clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3

input int    Periode=10;
input double Multiplier=3;
input bool   Show_Filling=true;
input int    ArrowDistance = 10;
input color  BuyColor = clrGreen;
input color  SellColor = clrRed;
input int    ArrowSize = 1;
input int    FillTransparency = 120;

double Filled_a[];
double Filled_b[];
double SuperTrend[];
double ColorBuffer[];
double Atr[];
double Up[];
double Down[];
double Middle[];
double trend[];

int atrHandle;
int changeOfTrend = 0;
int flag;
int flagh;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, Filled_a, INDICATOR_DATA);
    SetIndexBuffer(1, Filled_b, INDICATOR_DATA);
    SetIndexBuffer(2, SuperTrend, INDICATOR_DATA);
    SetIndexBuffer(3, ColorBuffer, INDICATOR_COLOR_INDEX);
    SetIndexBuffer(4, Atr, INDICATOR_CALCULATIONS);
    SetIndexBuffer(5, Up, INDICATOR_CALCULATIONS);
    SetIndexBuffer(6, Down, INDICATOR_CALCULATIONS);
    SetIndexBuffer(7, Middle, INDICATOR_CALCULATIONS);
    SetIndexBuffer(8, trend, INDICATOR_CALCULATIONS);

    IndicatorSetString(INDICATOR_SHORTNAME, "SuperTrend");

    // Create ATR handle
    atrHandle = iATR(_Symbol, _Period, Periode);
    if (atrHandle == INVALID_HANDLE)
    {
        Print("Failed to create ATR handle.");
        return (INIT_FAILED);
    }

    // Set color and transparency for filling
    color FillingColor = clrDarkRed | (FillTransparency << 24);
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, FillingColor);

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], 
                const double &close[], const long &tick_volume[], const long &volume[], 
                const int &spread[])
{
    // Ensure there are enough bars for ATR calculation
    if (rates_total <= Periode || rates_total < 10)
    {
        Print("Not enough bars to calculate ATR.");
        return prev_calculated;  // Return immediately if not enough data
    }

    // Fetch ATR values for all bars
    if (CopyBuffer(atrHandle, 0, 0, rates_total, Atr) <= 0) 
    {
        Print("Failed to retrieve ATR buffer. Error: ", GetLastError());
        return prev_calculated;
    }

    // Ensure we're only processing the fully formed bars
    int start = MathMax(prev_calculated - 1, Periode);
    if (prev_calculated == 0)
    {
        start = Periode;  // Start from the first valid bar if nothing was calculated yet
    }

    // Loop through the calculated bars
    for (int i = start; i < rates_total - 1; i++) // Skip the last bar (index 0)
    {
        // Validate ATR values, skip if invalid
        if (Atr[i] == EMPTY_VALUE || Atr[i] >= 1e10 || Atr[i] <= -1e10)
        {
            Print("Invalid ATR value detected at index ", i, ": ", Atr[i], ". Skipping this calculation.");
            continue;  // Skip invalid ATR values
        }

        // Print ATR value for each bar
        // Print("Bar: ", i, " | Time: ", TimeToString(time[i], TIME_DATE | TIME_MINUTES), " | ATR: ", Atr[i]);

        // Calculate the Middle, Up, Down, and SuperTrend values based on the valid ATR
        Middle[i] = (high[i] + low[i]) / 2;
        Up[i] = Middle[i] + (Multiplier * Atr[i]);
        Down[i] = Middle[i] - (Multiplier * Atr[i]);

        // Determine trend direction and signals
        if (close[i] > Up[i - 1])
        {
            trend[i] = 1;  // Uptrend
            if (trend[i - 1] == -1) changeOfTrend = 1;  // Detect a change of trend from down to up
        }
        else if (close[i] < Down[i - 1])
        {
            trend[i] = -1;  // Downtrend
            if (trend[i - 1] == 1) changeOfTrend = 1;  // Detect a change of trend from up to down
        }
        else
        {
            trend[i] = trend[i - 1];  // No change in trend
            changeOfTrend = 0;
        }

        // Prevent abrupt changes in the Up and Down lines
        if (trend[i] > 0 && Down[i] < Down[i - 1]) Down[i] = Down[i - 1];
        if (trend[i] < 0 && Up[i] > Up[i - 1]) Up[i] = Up[i - 1];

        // Set SuperTrend and color buffer based on the trend
        SuperTrend[i] = (trend[i] == 1) ? Down[i] : Up[i];
        ColorBuffer[i] = (trend[i] == 1) ? 0.0 : 1.0;

        // Handle filling logic (if filling is enabled)
        if (Show_Filling)
        {
            Filled_a[i] = SuperTrend[i];
            Filled_b[i] = close[i];
        }
        else
        {
            Filled_a[i] = EMPTY_VALUE;
            Filled_b[i] = EMPTY_VALUE;
        }
    }

    return rates_total;
}
