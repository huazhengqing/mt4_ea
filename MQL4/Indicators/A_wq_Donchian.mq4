//+------------------------------------------------------------------+
//|                      Donchian Channels - Generalized version.mq4 |
//|                         Copyright ?2005, Luis Guilherme Damiani |
//|                                      http://www.damianifx.com.br |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2005, Luis Guilherme Damiani"
#property link      "http://www.damianifx.com.br"


#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Magenta
#property indicator_color2 Magenta




extern int Periods = 40;



double ExtMapBuffer1[];
double ExtMapBuffer2[];


int init()
{
	SetIndexStyle(0, DRAW_LINE, STYLE_DOT);
	SetIndexBuffer(0,ExtMapBuffer1);
	
	SetIndexStyle(1, DRAW_LINE, STYLE_DOT);
	SetIndexBuffer(1,ExtMapBuffer2);
	
	return(0);
}


int deinit()
{
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
	//int c = rates_total;
	//int clac_pre_bars = 89 * 2 + 0 + 1 + 25 * 15;
	int clac_pre_bars = 1;
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
	for (int shift = limit - 1; shift >= 0; shift--)
	{
		ExtMapBuffer1[shift]=Low[Lowest(NULL,0,MODE_LOW,Periods,shift)];
		ExtMapBuffer2[shift]=High[Highest(NULL,0,MODE_HIGH,Periods,shift)];
	}
	
	return(0);
}





