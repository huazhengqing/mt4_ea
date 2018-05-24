#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 clrLime
#property indicator_color2 clrRed
#property indicator_width1 0
#property indicator_width2 0


#include <wq_bars.mqh>

bars* g_bars = NULL;

double g_buy[];
double g_sell[];



int init()
{
	SetIndexBuffer(0, g_buy);
	SetIndexStyle(0, DRAW_ARROW);
	SetIndexArrow(0, 233);
	SetIndexEmptyValue(0, EMPTY_VALUE);
	
	
	SetIndexBuffer(1, g_sell);
	SetIndexStyle(1, DRAW_ARROW);
	SetIndexArrow(1, 234);
	SetIndexEmptyValue(1, EMPTY_VALUE);
	

	g_bars = new bars(Symbol(), Period());

	return(0);
}

int deinit()
{
	delete g_bars;
	return(0);
}

int start()
{
	int counted_bars = IndicatorCounted();
	if (counted_bars < 0) 
	{
		return (-1);
	}
	int c = Bars;
	int clac_pre_bars = 6;
	if (c < clac_pre_bars) 
	{
		return (0);
	}
	if (counted_bars > 0) 
	{
		counted_bars = counted_bars - 1;
	}
	int limit = c - counted_bars;
	if (limit > c - clac_pre_bars) 
	{
		limit = c - clac_pre_bars;
	}
	for (int i = limit - 1; i >= 0; i--)
	{
	
		is_new_bar(i);
		g_bars.tick_start();
		g_bars.calc(i);
		
		if (g_bars.is_sideways())
		{
			continue;
		}
		if (g_bars.check_volatile() <= 0)
		{
			continue;
		}
		
		int t = g_bars.check_trend();
		if (t == 1)
		{
			g_buy[i] = Low[i] - (g_bars._bars[1]._atr) * 3;
		}
		else if (t == -1)
		{
			g_sell[i] = High[i] + (g_bars._bars[1]._atr) * 3;
		}
	}
	
	return(0);
}




