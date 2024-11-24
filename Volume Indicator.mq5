//+------------------------------------------------------------------+
//|                        VolumeProfile.mq5                         |
//|                   Custom Volume Profile Indicator                |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "High Volume Level"
#property indicator_label2 "Low Volume Level"

// Input parameters
input int Period = 20;        // Look-back period for volume profile

// Buffers for high and low volume levels
double highVolumeBuffer[];
double lowVolumeBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, highVolumeBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, lowVolumeBuffer, INDICATOR_DATA);

    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);

    // Set plot styles and colors if desired
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrBlue);
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrRed);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    if (rates_total <= Period) return 0;

    // Calculate high and low volume levels within the look-back period
    for (int i = prev_calculated; i < rates_total; i++)
    {
        long maxVolume = 0;
        long minVolume = 2147483647; // Replaced LONG_MAX with maximum value for 32-bit long
        double highVolumeLevel = 0.0;
        double lowVolumeLevel = 0.0;

        for (int j = 0; j < Period; j++)
        {
            int index = i - j;
            if (index < 0) break;

            if (tick_volume[index] > maxVolume)
            {
                maxVolume = tick_volume[index];
                highVolumeLevel = close[index];
            }
            if (tick_volume[index] < minVolume)
            {
                minVolume = tick_volume[index];
                lowVolumeLevel = close[index];
            }
        }

        highVolumeBuffer[i] = highVolumeLevel;
        lowVolumeBuffer[i] = lowVolumeLevel;
    }

    return rates_total;
}