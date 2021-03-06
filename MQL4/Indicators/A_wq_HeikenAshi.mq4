#property strict
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 C'224,001,006'
#property indicator_color2 C'031,192,071'
#property indicator_color3 C'224,001,006'
#property indicator_color4 C'031,192,071'


color ExtColor1 = C'224,001,006';	// Shadow of bear candlestick
color ExtColor2 = C'031,192,071';	// Shadow of bull candlestick
color ExtColor3 = C'224,001,006';	// Bear candlestick body
color ExtColor4 = C'031,192,071';	// Bull candlestick body


double ExtOpenBuffer[];
double ExtCloseBuffer[];

double ExtLowHighBuffer[];
double ExtHighLowBuffer[];


void OnInit(void)
{
	IndicatorDigits(Digits);
	
	SetIndexStyle(0,DRAW_HISTOGRAM,0,2,ExtColor3);
	SetIndexBuffer(0,ExtOpenBuffer);
	SetIndexDrawBegin(0,10);
	
	SetIndexStyle(1,DRAW_HISTOGRAM,0,2,ExtColor4);
	SetIndexBuffer(1,ExtCloseBuffer);
	SetIndexDrawBegin(1,10);
	
	SetIndexStyle(2,DRAW_HISTOGRAM,0,0,ExtColor1);
	SetIndexBuffer(2,ExtLowHighBuffer);
	SetIndexDrawBegin(2,10);
	
	SetIndexStyle(3,DRAW_HISTOGRAM,0,0,ExtColor2);
	SetIndexBuffer(3,ExtHighLowBuffer);
	SetIndexDrawBegin(3,10);
}

int deinit()
{
	return(0);
}

/*
当前柱的收盘价：haClose = (Open + High + Low + Close) / 4 
当前柱的开盘价：haOpen = (haOpen [before.]+ HaClose [before]) / 2 
当前柱的最高价：haHigh = Max (High, haOpen, haClose) 
当前柱的最低价：haLow = Min (Low, haOpen, haClose) 
*/
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
	int i,pos;
	double haOpen,haHigh,haLow,haClose;
	
	if(rates_total<=10)
		return(0);
	
	ArraySetAsSeries(ExtLowHighBuffer,false);
	ArraySetAsSeries(ExtHighLowBuffer,false);
	ArraySetAsSeries(ExtOpenBuffer,false);
	ArraySetAsSeries(ExtCloseBuffer,false);
	ArraySetAsSeries(open,false);
	ArraySetAsSeries(high,false);
	ArraySetAsSeries(low,false);
	ArraySetAsSeries(close,false);
   
	if(prev_calculated>1)
	{
		pos=prev_calculated-1;
	}
	else
	{
		//--- set first candle
		if(open[0]<close[0])
		{
			ExtLowHighBuffer[0]=low[0];
			ExtHighLowBuffer[0]=high[0];
		}
		else
		{
			ExtLowHighBuffer[0]=high[0];
			ExtHighLowBuffer[0]=low[0];
		}
		ExtOpenBuffer[0]=open[0];
		ExtCloseBuffer[0]=close[0];
		
		pos=1;
	}
	
	for(i=pos; i<rates_total; i++)
	{
		haOpen=(ExtOpenBuffer[i-1]+ExtCloseBuffer[i-1])/2;
		haClose=(open[i]+high[i]+low[i]+close[i])/4;
		haHigh=MathMax(high[i],MathMax(haOpen,haClose));
		haLow=MathMin(low[i],MathMin(haOpen,haClose));
		if(haOpen<haClose)
		{
			ExtLowHighBuffer[i]=haLow;
			ExtHighLowBuffer[i]=haHigh;
		}
		else
		{
			ExtLowHighBuffer[i]=haHigh;
			ExtHighLowBuffer[i]=haLow;
		}
		ExtOpenBuffer[i]=haOpen;
		ExtCloseBuffer[i]=haClose;
	}

	return(rates_total);
}

