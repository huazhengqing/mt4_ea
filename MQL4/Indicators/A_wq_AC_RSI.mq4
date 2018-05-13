#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 clrLime
#property indicator_color2 clrLime
#property indicator_color3 clrRed
#property indicator_color4 clrRed
#property indicator_width1 0
#property indicator_width2 0
#property indicator_width3 0
#property indicator_width4 0


input int period = 11;

double g_rsi = 0.0;
int g_index_ac = 0;
double g_atr = 0.0;

double g_buy[];
double g_buy_close[];
double g_sell[];
double g_sell_close[];

bool g_buy_flag = false;
bool g_sell_flag = false;


int init()
{
	SetIndexBuffer(0, g_buy);
	SetIndexStyle(0, DRAW_ARROW);
	SetIndexArrow(0, 225);
	SetIndexEmptyValue(0, EMPTY_VALUE);
	
	SetIndexBuffer(1, g_buy_close);
	SetIndexStyle(1, DRAW_ARROW);
	SetIndexArrow(1, 251);
	SetIndexEmptyValue(1, EMPTY_VALUE);
	
	SetIndexBuffer(2, g_sell);
	SetIndexStyle(2, DRAW_ARROW);
	SetIndexArrow(2, 226);
	SetIndexEmptyValue(2, EMPTY_VALUE);
	
	SetIndexBuffer(3, g_sell_close);
	SetIndexStyle(3, DRAW_ARROW);
	SetIndexArrow(3, 251);
	SetIndexEmptyValue(3, EMPTY_VALUE);

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
		g_rsi = iRSI(Symbol(), Period(), period, PRICE_CLOSE, i);
		speed_ac(i);
		g_atr = iATR(Symbol(), Period(), 16, i);
		
		if (!g_buy_flag)
		{
			if (g_rsi >= 70.0 && g_index_ac >= 1)
			{
				g_buy[i] = Low[i] - (g_atr) * 1.5;
				g_buy_flag = true;
				g_sell_flag = false;
			}
		}
		if (!g_sell_flag)
		{
			if (g_rsi <= 30.0 && g_index_ac <= -1)
			{
				g_sell[i] = High[i] + (g_atr) * 1.5;
				g_sell_flag = true;
				g_buy_flag = false;
			}
		}
		if (g_buy_flag)
		{
			if (g_index_ac < 0
				&& g_rsi > 70.0
				)
			{
				g_buy_close[i] = High[i] + (g_atr) * 1;
				g_buy_flag = false;
			}
		}
		if (g_sell_flag)
		{
			if (g_index_ac > 0
				&& g_rsi < 30.0
				)
			{
				g_sell_close[i] = Low[i] - (g_atr) * 1;
				g_sell_flag = false;
			}
		}
	}
	
	return(0);
}

void speed_ac(int j)
{
	double ac[];
   ArrayResize(ac,5);
	for(int i=0; i<5; i++)
		ac[i]=iAC(Symbol(), Period(), i+j);
	g_index_ac=0;
	if(ac[0]>ac[1] && ac[1]>ac[2] && ac[2]>ac[3] && ac[3]>ac[4])
		g_index_ac=4;
	else if(ac[0]>ac[1] && ac[1]>ac[2] && ac[2]>ac[3])
		g_index_ac=3;
	else if(ac[0]>ac[1] && ac[1]>ac[2])
		g_index_ac=2;
	else if(ac[0]>ac[1])
		g_index_ac=1;
	else if(ac[0]<ac[1] && ac[1]<ac[2] && ac[2]<ac[3] && ac[3]<ac[4])
		g_index_ac=-4;
	else if(ac[0]<ac[1] && ac[1]<ac[2] && ac[2]<ac[3])
		g_index_ac=-3;
	else if(ac[0]<ac[1] && ac[1]<ac[2])
		g_index_ac=-2;
	else if(ac[0]<ac[1])
		g_index_ac=-1;
}

string get_time_frame_str(int time_frame)
{
	if (time_frame == 0)
	{
		time_frame = Period();
	}
	switch (time_frame)
	{
	case PERIOD_M1: return "M1";break;
	case PERIOD_M5: return "M5";break;
	case PERIOD_M15: return "M15";break;
	case PERIOD_M30: return "M30";break;
	case PERIOD_H1: return "H1";break;
	case PERIOD_H4: return "H4";break;
	case PERIOD_D1: return "D1";break;
	}
	return "";
}


datetime g_alert_time = 0;
void alert(string msg)
{
	if (IsTesting() || IsDemo() || IsStopped())
	{
		return;
	}
	if (StringLen(msg) <= 0)
	{
		return;
	}
	const string s = "[" + Symbol() + "][" + get_time_frame_str(Period()) + "][AC_RSI]" + msg;
	if (g_alert_time < iTime(Symbol(), Period(), 0))
	{
		g_alert_time = iTime(Symbol(), Period(), 0);
		Alert(s);
	}
}



