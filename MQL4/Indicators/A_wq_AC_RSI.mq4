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


input int period = 8;


int g_index_rsi = 0;
int g_index_ac = 0;


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
		depth_trend(i);
		speed_ac(i);
		double atr = iATR(Symbol(), Period(), 16, i);
		
		if (!g_buy_flag)
		{
			if (Buy())
			{
				g_buy[i] = Low[i] - (atr) * 1.5;
				g_buy_flag = true;
				g_sell_flag = false;
				if (i <= 0)
					SendAlert("buy");
			}
		}
		if (!g_sell_flag)
		{
			if (Sell())
			{
				g_sell[i] = High[i] + (atr) * 1.5;
				g_sell_flag = true;
				g_buy_flag = false;
				if (i <= 0)
					SendAlert("sell");
			}
		}
		if (g_buy_flag)
		{
			if(Buy_close())
			{
				g_buy_close[i] = High[i] + (atr) * 1;
				g_buy_flag = false;
				if (i <= 0)
					SendAlert("buy_close");
			}
		}
		if (g_sell_flag)
		{
			if(Sell_close())
			{
				g_sell_close[i] = Low[i] - (atr) * 1;
				g_sell_flag = false;
				if (i <= 0)
					SendAlert("sell_close");
			}
		}
	}
	
	return(0);
}

void depth_trend(int i)
{
	double rsi = iRSI(Symbol(), Period(), period, PRICE_CLOSE, i);
	g_index_rsi = 0;
	if(rsi>90.0) 
		g_index_rsi=4;
	else if(rsi>80.0)
		g_index_rsi=3;
	else if(rsi>70.0)
		g_index_rsi=2;
	else if(rsi>60.0)
		g_index_rsi=1;
	else if(rsi<10.0)
		g_index_rsi=-4;
	else if(rsi<20.0)
		g_index_rsi=-3;
	else if(rsi<30.0)
		g_index_rsi=-2;
	else if(rsi<40.0)
		g_index_rsi=-1;
}

void speed_ac(int j)
{
	double ac[];
   ArrayResize(ac,5);
	for(int i=0; i<5; i++)
		ac[i]=iAC(Symbol(), Period(), i+j);
	g_index_ac=0;
	if(ac[0]>ac[1])
		g_index_ac=1;
	else if(ac[0]>ac[1] && ac[1]>ac[2])
		g_index_ac=2;
	else if(ac[0]>ac[1] && ac[1]>ac[2] && ac[2]>ac[3])
		g_index_ac=3;
	else if(ac[0]>ac[1] && ac[1]>ac[2] && ac[2]>ac[3] && ac[3]>ac[4])
		g_index_ac=4;
	else if(ac[0]<ac[1])
		g_index_ac=-1;
	else if(ac[0]<ac[1] && ac[1]<ac[2])
		g_index_ac=-2;
	else if(ac[0]<ac[1] && ac[1]<ac[2] && ac[2]<ac[3])
		g_index_ac=-3;
	else if(ac[0]<ac[1] && ac[1]<ac[2] && ac[2]<ac[3] && ac[3]<ac[4])
		g_index_ac=-4;
}

bool Buy()
{
	bool res=false;
	if((g_index_rsi==2 && g_index_ac>=1) || (g_index_rsi==3 && g_index_ac==1))
		res=true;
	return (res);
}

bool Sell()
{
	bool res=false;
	if((g_index_rsi==-2 && g_index_ac<=-1) || (g_index_rsi==-3 && g_index_ac==-1))
		res=true;
	return (res);
}

bool Buy_close()
{
	bool res=false;
	if(g_index_rsi>2 && g_index_ac<0)
		res=true;
	return (res);
}

bool Sell_close()
{
	bool res=false;
	if(g_index_rsi<-2 && g_index_ac>0)
		res=true;
	return (res);
}

string TimeframeToString(int P)
{
   switch(P)
   {
      case PERIOD_M1:  return("M1");
      case PERIOD_M5:  return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H4:  return("H4");
      case PERIOD_D1:  return("D1");
      case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN1");
   }
   return("");
}

void SendAlert(string dir)
{
	Alert("[", Symbol(), "][", TimeframeToString(Period()), "][AC_RSI][", dir, "]");
	//PlaySound("alert.wav");
}




